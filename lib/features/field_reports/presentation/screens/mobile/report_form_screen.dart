import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../data/storage/photo_storage_service.dart';
import '../../../../../domain/enums/report_status.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/report_form_cubit.dart';
import '../../state/report_form_state.dart';
import '../../widgets/labor_count_input.dart';
import '../../widgets/report_form_fields.dart';
import '../../widgets/report_photo_attach.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/weather_selector.dart';
import 'report_preview_screen.dart';

/// شاشة تعبئة/تحرير مسوّدة تقرير ميداني — تعمل مباشرة فوق
/// [ReportFormData.report] الحالية في [ReportFormCubit] (`Navigator.push`
/// من `field_reports_mobile_home.dart`/`my_reports_screen.dart`/
/// `report_drafts_screen.dart`، بلا أي معامل مسار — الكائن نفسه مُهيَّأ
/// مسبقاً عبر `startNewDraft()`/`resumeExisting()` قبل الدخول). كل تعديل
/// حقل يُشغّل حفظاً تلقائياً مؤجَّلاً (Debounce، انظر `report_form_cubit.dart`)،
/// وزر "معاينة" يحفظ فوراً قبل الانتقال لـ [ReportPreviewScreen].
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  bool _attemptedSubmit = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) context.read<ReportFormCubit>().saveNow();
      },
      child: BlocBuilder<ReportFormCubit, ReportFormState>(
        builder: (BuildContext context, ReportFormState state) {
          final ReportFormData? data = state.dataOrNull;
          if (data == null) {
            return const Scaffold(body: LoadingIndicator());
          }

          if (!data.report.status.isDraft) {
            return _AlreadySubmittedView(status: data.report.status);
          }

          final ReportFormCubit cubit = context.read<ReportFormCubit>();
          final String? workPerformedError =
              (_attemptedSubmit && (data.report.workPerformed?.trim().isEmpty ?? true))
                  ? 'وصف العمل المُنجز مطلوب قبل التقديم.'
                  : null;

          return Scaffold(
            appBar: AppBar(
              title: Text(DateFormatter.shortDate(data.report.reportDate)),
              actions: <Widget>[
                if (data.isSaving)
                  const Padding(
                    padding: EdgeInsets.only(left: AvahiSpacing.md),
                    child: Center(
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: AvahiSpacing.md),
                    child: Center(
                      child: Icon(Icons.cloud_done_outlined, color: context.colors.primary),
                    ),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AvahiSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ReportDateTile(
                    date: data.report.reportDate,
                    onChanged: cubit.updateReportDate,
                  ),
                  const SizedBox(height: AvahiSpacing.lg),
                  WeatherSelector(
                    condition: data.report.weatherCondition,
                    temperatureC: data.report.temperatureC,
                    isLoading: data.isWeatherLoading,
                    errorMessage: data.weatherError,
                    onRetry: cubit.retryWeatherFill,
                    onConditionChanged: cubit.updateWeatherCondition,
                    onTemperatureChanged: cubit.updateTemperature,
                  ),
                  const SizedBox(height: AvahiSpacing.lg),
                  LaborCountInput(
                    count: data.report.laborCount,
                    onChanged: cubit.updateLaborCount,
                  ),
                  const SizedBox(height: AvahiSpacing.lg),
                  ReportFormFields(
                    workPerformed: data.report.workPerformed,
                    materialsUsed: data.report.materialsUsed,
                    equipmentUsed: data.report.equipmentUsed,
                    issues: data.report.issues,
                    notes: data.report.notes,
                    workPerformedError: workPerformedError,
                    onWorkPerformedChanged: cubit.updateWorkPerformed,
                    onMaterialsUsedChanged: cubit.updateMaterialsUsed,
                    onEquipmentUsedChanged: cubit.updateEquipmentUsed,
                    onIssuesChanged: cubit.updateIssues,
                    onNotesChanged: cubit.updateNotes,
                  ),
                  const SizedBox(height: AvahiSpacing.lg),
                  ReportPhotoAttach(
                    photos: data.photos,
                    isUploading: data.isUploadingPhoto,
                    onAddFromCamera: cubit.attachPhotoFromCamera,
                    onAddFromGallery: cubit.attachPhotoFromGallery,
                    onRemove: cubit.removePhoto,
                    resolveSignedUrl: (String path) async {
                      final result = await sl<PhotoStorageService>().getSignedUrl(path);
                      return result.getOrNull();
                    },
                  ),
                  const SizedBox(height: AvahiSpacing.xl),
                  AvahiButton(
                    label: 'معاينة التقرير',
                    icon: Icons.arrow_forward,
                    isFullWidth: true,
                    onPressed: () async {
                      setState(() => _attemptedSubmit = true);
                      final bool hasWork = data.report.workPerformed?.trim().isNotEmpty ?? false;
                      if (!hasWork) {
                        context.showSnackBar('يرجى وصف العمل المُنجز قبل المتابعة.');
                        return;
                      }
                      final bool saved = await cubit.saveNow();
                      if (!saved) {
                        if (context.mounted) {
                          context.showSnackBar('تعذّر حفظ التقرير — تحقق من الاتصال وحاول مجدداً.');
                        }
                        return;
                      }
                      if (context.mounted) {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReportPreviewScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AvahiSpacing.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportDateTile extends StatelessWidget {
  const _ReportDateTile({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: const Text('تاريخ التقرير'),
      subtitle: Text(DateFormatter.longDate(date)),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 60)),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _AlreadySubmittedView extends StatelessWidget {
  const _AlreadySubmittedView({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقرير')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AvahiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: AvahiSpacing.md),
              ReportStatusBadge(status: status),
              const SizedBox(height: AvahiSpacing.sm),
              const Text(
                'تم تقديم هذا التقرير ولم يعد قابلاً للتعديل.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AvahiSpacing.lg),
              AvahiButton(
                label: 'عرض المعاينة',
                onPressed: () => Navigator.of(context).pushReplacement<void, void>(
                  MaterialPageRoute<void>(builder: (_) => const ReportPreviewScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
