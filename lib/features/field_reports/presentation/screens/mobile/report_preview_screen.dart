import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/storage/photo_storage_service.dart';
import '../../../../../data/storage/signature_storage_service.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/report_form_cubit.dart';
import '../../state/report_form_state.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/weather_selector.dart';
import 'report_signature_screen.dart';

/// معاينة نهائية شاملة لكل بيانات التقرير — الطقس، عدد العمّال، الحقول
/// النصية الخمسة، الصور المرفقة، والتواقيع المصغّرة إن وُجدت (تقرير
/// موقَّع مسبقاً). زر "التالي: التوقيع" يظهر فقط للمسوّدات
/// (`report_signature_screen.dart`)؛ لتقرير مُقدَّم/معتمد/مرفوض بالفعل
/// تُعرض الشاشة بلا أي إجراء، للاطلاع فقط.
class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportFormCubit, ReportFormState>(
      builder: (BuildContext context, ReportFormState state) {
        final ReportFormData? data = state.dataOrNull;
        if (data == null) return const Scaffold(body: LoadingIndicator());

        final report = data.report;

        return Scaffold(
          appBar: AppBar(
            title: const Text('معاينة التقرير'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: AvahiSpacing.md),
                child: Center(child: ReportStatusBadge(status: report.status)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionTitle(DateFormatter.longDate(report.reportDate)),
                const SizedBox(height: AvahiSpacing.md),
                if (report.weatherCondition != null) ...<Widget>[
                  _PreviewRow(
                    icon: weatherConditionDisplay(report.weatherCondition!).$1,
                    label: 'الطقس',
                    value: report.temperatureC == null
                        ? weatherConditionDisplay(report.weatherCondition!).$2
                        : '${weatherConditionDisplay(report.weatherCondition!).$2}، '
                            '${report.temperatureC!.toStringAsFixed(0)}°م',
                  ),
                  const SizedBox(height: AvahiSpacing.sm),
                ],
                _PreviewRow(
                  icon: Icons.people_outline,
                  label: 'عدد العمّال',
                  value: '${report.laborCount}',
                ),
                const Divider(height: AvahiSpacing.xl),
                _PreviewSection(title: 'العمل المُنجز', value: report.workPerformed),
                _PreviewSection(title: 'المواد المستخدَمة', value: report.materialsUsed),
                _PreviewSection(title: 'المعدات المستخدَمة', value: report.equipmentUsed),
                _PreviewSection(title: 'مشاكل/عوائق', value: report.issues),
                _PreviewSection(title: 'ملاحظات إضافية', value: report.notes),
                if (data.photos.isNotEmpty) ...<Widget>[
                  const Divider(height: AvahiSpacing.xl),
                  _SectionTitle('الصور المرفقة (${data.photos.length})'),
                  const SizedBox(height: AvahiSpacing.sm),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AvahiSpacing.xs),
                      itemBuilder: (BuildContext context, int index) {
                        final photo = data.photos[index];
                        return ClipRRect(
                          borderRadius: AvahiRadius.radiusMd,
                          child: FutureBuilder<String?>(
                            future: sl<PhotoStorageService>()
                                .getSignedUrl(photo.storagePath)
                                .then((r) => r.getOrNull()),
                            builder: (_, AsyncSnapshot<String?> snapshot) {
                              final String? url = snapshot.data;
                              return SizedBox(
                                width: 90,
                                height: 90,
                                child: url == null
                                    ? const ColoredBox(color: Colors.black12)
                                    : Image.network(url, fit: BoxFit.cover),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (report.supervisorSignatureUrl != null || report.clientSignatureUrl != null) ...<Widget>[
                  const Divider(height: AvahiSpacing.xl),
                  const _SectionTitle('التواقيع'),
                  const SizedBox(height: AvahiSpacing.sm),
                  Row(
                    children: <Widget>[
                      if (report.supervisorSignatureUrl != null)
                        Expanded(
                          child: _SignatureThumbnail(
                            label: 'المشرف',
                            storagePath: report.supervisorSignatureUrl!,
                          ),
                        ),
                      if (report.supervisorSignatureUrl != null &&
                          report.clientSignatureUrl != null)
                        const SizedBox(width: AvahiSpacing.sm),
                      if (report.clientSignatureUrl != null)
                        Expanded(
                          child: _SignatureThumbnail(
                            label: 'العميل',
                            storagePath: report.clientSignatureUrl!,
                          ),
                        ),
                    ],
                  ),
                ],
                if (report.status.isRejected && report.rejectionReason != null) ...<Widget>[
                  const Divider(height: AvahiSpacing.xl),
                  const _SectionTitle('سبب الرفض'),
                  const SizedBox(height: AvahiSpacing.xs),
                  Text(report.rejectionReason!),
                ],
                if (report.status.isDraft) ...<Widget>[
                  const SizedBox(height: AvahiSpacing.xl),
                  AvahiButton(
                    label: 'التالي: التوقيع',
                    icon: Icons.draw_outlined,
                    isFullWidth: true,
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => const ReportSignatureScreen()),
                    ),
                  ),
                ],
                const SizedBox(height: AvahiSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: AvahiSpacing.xs),
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEmpty = value == null || value!.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.xxs),
          Text(
            isEmpty ? 'بلا بيانات' : value!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEmpty ? colors.onSurfaceVariant : null,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
          ),
        ],
      ),
    );
  }
}

class _SignatureThumbnail extends StatelessWidget {
  const _SignatureThumbnail({required this.label, required this.storagePath});

  final String label;
  final String storagePath;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AvahiSpacing.xxs),
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
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
