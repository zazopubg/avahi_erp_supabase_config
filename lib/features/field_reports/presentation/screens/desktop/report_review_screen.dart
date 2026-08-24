import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../data/storage/photo_storage_service.dart';
import '../../../../../data/storage/signature_storage_service.dart';
import '../../../../../domain/entities/field_report.dart';
import '../../../../../domain/entities/site_photo.dart';
import '../../../../../domain/enums/related_entity_type.dart';
import '../../../../../domain/repositories/i_photo_repository.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../state/reports_inbox_cubit.dart';
import '../../state/reports_inbox_state.dart';
import '../../widgets/report_approval_actions.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/weather_selector.dart';

/// لوحة مراجعة تقرير جانبية لسطح المكتب — النظير الإداري المباشر لـ
/// `report_preview_screen.dart` (الهاتفية)، لكن كلوحة ثابتة ضمن
/// التخطيط ثنائي الأعمدة لـ `reports_inbox.dart`/`reports_archive.dart`
/// بدل صفحة منفصلة، بنفس نمط `task_details_panel.dart` تماماً — تقرأ
/// [reportId] فقط وتحلّه في كل مرة من [ReportsInboxData] الحالية (تعكس
/// أي تحديث لحظي فوري دون إعادة اختيار يدوية).
class ReportReviewScreen extends StatelessWidget {
  const ReportReviewScreen({required this.reportId, super.key, this.onClose});

  final String reportId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return BlocBuilder<ReportsInboxCubit, ReportsInboxState>(
      builder: (BuildContext context, ReportsInboxState state) {
        final ReportsInboxData? data = state.dataOrNull;
        final FieldReport? report = data?.reports
            .cast<FieldReport?>()
            .firstWhere((FieldReport? r) => r?.id == reportId, orElse: () => null);

        return Container(
          width: 400,
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(left: BorderSide(color: colors.outlineVariant)),
          ),
          child: report == null
              ? Center(
                  child: Text(
                    'اختر تقريراً لعرض تفاصيله',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : _PanelContent(report: report, onClose: onClose),
        );
      },
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.report, this.onClose});

  final FieldReport report;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                DateFormatter.longDate(report.reportDate),
                style: context.textTheme.titleLarge,
              ),
            ),
            if (onClose != null)
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          ],
        ),
        const SizedBox(height: AvahiSpacing.xs),
        ReportStatusBadge(status: report.status),
        if (report.weatherCondition != null) ...<Widget>[
          const SizedBox(height: AvahiSpacing.md),
          _DetailRow(
            label: 'الطقس',
            value: report.temperatureC == null
                ? weatherConditionDisplay(report.weatherCondition!).$2
                : '${weatherConditionDisplay(report.weatherCondition!).$2}، '
                    '${report.temperatureC!.toStringAsFixed(0)}°م',
          ),
        ],
        _DetailRow(label: 'عدد العمّال', value: '${report.laborCount}'),
        const SizedBox(height: AvahiSpacing.lg),
        _Section(title: 'العمل المُنجز', value: report.workPerformed),
        _Section(title: 'المواد المستخدَمة', value: report.materialsUsed),
        _Section(title: 'المعدات المستخدَمة', value: report.equipmentUsed),
        _Section(title: 'مشاكل/عوائق', value: report.issues),
        _Section(title: 'ملاحظات إضافية', value: report.notes),
        if (report.rejectionReason != null)
          _Section(title: 'سبب الرفض السابق', value: report.rejectionReason),
        if (report.supervisorSignatureUrl != null || report.clientSignatureUrl != null) ...<Widget>[
          const SizedBox(height: AvahiSpacing.sm),
          Text('التواقيع', style: context.textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.xs),
          Row(
            children: <Widget>[
              if (report.supervisorSignatureUrl != null)
                Expanded(
                  child: _SignatureThumb(
                    label: 'المشرف',
                    storagePath: report.supervisorSignatureUrl!,
                  ),
                ),
              if (report.supervisorSignatureUrl != null && report.clientSignatureUrl != null)
                const SizedBox(width: AvahiSpacing.sm),
              if (report.clientSignatureUrl != null)
                Expanded(
                  child: _SignatureThumb(
                    label: 'العميل',
                    storagePath: report.clientSignatureUrl!,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AvahiSpacing.lg),
        _ReportPhotosSection(reportId: report.id),
        if (report.status.isSubmitted) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xl),
          _ReviewActions(report: report),
        ],
      ],
    );
  }
}

/// قسم صور التقرير — يُحمَّل كسولاً عبر `IPhotoRepository` مباشرة (لا
/// حالة مخصصة لهذا ضمن `ReportsInboxCubit` نفسه، تشابهاً مع أسلوب
/// `report_photo_attach.dart` في الجانب الهاتفي).
class _ReportPhotosSection extends StatelessWidget {
  const _ReportPhotosSection({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SitePhoto>>(
      future: sl<IPhotoRepository>()
          .getPhotosForEntity(
            relatedEntityType: RelatedEntityType.fieldReport,
            relatedEntityId: reportId,
          )
          .then((r) => r.getOrNull() ?? const <SitePhoto>[]),
      builder: (BuildContext context, AsyncSnapshot<List<SitePhoto>> snapshot) {
        final List<SitePhoto> photos = snapshot.data ?? const <SitePhoto>[];
        if (snapshot.connectionState != ConnectionState.done || photos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('الصور المرفقة (${photos.length})', style: context.textTheme.titleSmall),
            const SizedBox(height: AvahiSpacing.xs),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: AvahiSpacing.xs),
                itemBuilder: (BuildContext context, int index) {
                  return ClipRRect(
                    borderRadius: AvahiRadius.radiusSm,
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: FutureBuilder<String?>(
                        future: sl<PhotoStorageService>()
                            .getSignedUrl(photos[index].storagePath)
                            .then((r) => r.getOrNull()),
                        builder: (_, AsyncSnapshot<String?> s) {
                          final String? url = s.data;
                          return url == null
                              ? const ColoredBox(color: Colors.black12)
                              : Image.network(url, fit: BoxFit.cover);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({required this.report});

  final FieldReport report;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsInboxCubit, ReportsInboxState>(
      builder: (BuildContext context, ReportsInboxState state) {
        final bool isReviewing = state.dataOrNull?.isReviewing ?? false;

        return ReportApprovalActions(
          isProcessing: isReviewing,
          onApprove: () async {
            final ReportsInboxData? data = context.read<ReportsInboxCubit>().state.dataOrNull;
            if (data == null) return;
            final bool success = await context.read<ReportsInboxCubit>().review(
                  report: report,
                  approve: true,
                  reviewerId: data.currentUser.userId,
                );
            if (!context.mounted) return;
            context.showSnackBar(success ? 'تم اعتماد التقرير.' : 'تعذّر اعتماد التقرير — حاول مجدداً.');
          },
          onReject: (String reason) async {
            final ReportsInboxData? data = context.read<ReportsInboxCubit>().state.dataOrNull;
            if (data == null) return;
            final bool success = await context.read<ReportsInboxCubit>().review(
                  report: report,
                  approve: false,
                  reviewerId: data.currentUser.userId,
                  rejectionReason: reason,
                );
            if (!context.mounted) return;
            context.showSnackBar(success ? 'تم رفض التقرير.' : 'تعذّر رفض التقرير — حاول مجدداً.');
          },
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = value == null || value!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.xxs),
          Text(
            isEmpty ? 'بلا بيانات' : value!,
            style: context.textTheme.bodyMedium?.copyWith(
                  color: isEmpty ? context.colors.onSurfaceVariant : null,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
      child: Row(
        children: <Widget>[
          Text(label, style: context.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SignatureThumb extends StatelessWidget {
  const _SignatureThumb({required this.label, required this.storagePath});

  final String label;
  final String storagePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: context.textTheme.labelMedium),
        const SizedBox(height: AvahiSpacing.xxs),
        Container(
          height: 70,
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.outlineVariant),
            borderRadius: AvahiRadius.radiusSm,
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: AvahiRadius.radiusSm,
            child: FutureBuilder<String?>(
              future: sl<SignatureStorageService>()
                  .getSignedUrl(storagePath)
                  .then((r) => r.getOrNull()),
              builder: (_, AsyncSnapshot<String?> snapshot) {
                final String? url = snapshot.data;
                return url == null
                    ? const SizedBox.shrink()
                    : Image.network(url, fit: BoxFit.contain);
              },
            ),
          ),
        ),
      ],
    );
  }
}
