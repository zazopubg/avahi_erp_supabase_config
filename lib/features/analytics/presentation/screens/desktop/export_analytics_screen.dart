import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../state/analytics_cubit.dart';
import '../../state/analytics_state.dart';
import '../../widgets/kpi_summary_row.dart';
import '../../widgets/project_progress_chart.dart';
import '../../widgets/task_distribution_chart.dart';
import 'analytics_dashboard.dart' show SectionCard;

/// لسان "التصدير" ضمن `analytics_dashboard.dart` — معاينة مباشرة
/// للوحة مختصرة (KPIs + تقدّم المشاريع + توزيع المهام) ضمن
/// [RepaintBoundary] (مرجع [_previewKey]) بالإضافة إلى زرَّي تصدير:
///
/// - **"تصدير PDF"**: يستدعي [AnalyticsCubit.exportDashboardAsPdf]
///   مباشرة — الكوبت يبني ملف PDF كاملاً بذاته (بيانات نصية/جدولية،
///   لا يحتاج التقاط صورة الشاشة) ويفتح حوار طباعة/حفظ المتصفح.
/// - **"تصدير صورة"**: يلتقط بايتات PNG من [_previewKey] هنا (أمر لا
///   يمكن نقله إلى الـ Cubit — يتطلّب وصولاً مباشراً لشجرة الودجات
///   عبر `RenderRepaintBoundary`) ثم يمرّرها إلى
///   [AnalyticsCubit.exportSectionAsImage] الذي يتولى التنزيل الفعلي.
///
/// ⚠️ قرار تصميم (لا حاجة لـ [BuildContext] داخل الـ Cubit): تقسيم
/// المسؤولية هذا (التقاط الصورة هنا، التنزيل الفعلي في الكوبت) يحافظ
/// على استقلالية `AnalyticsCubit` عن `Flutter Widgets` قدر الإمكان —
/// طبقة العرض (هذا الملف) هي الوحيدة التي تلمس شجرة الودجات مباشرة.
class ExportAnalyticsScreen extends StatefulWidget {
  const ExportAnalyticsScreen({
    required this.data,
    required this.isExporting,
    super.key,
  });

  final AnalyticsData data;
  final bool isExporting;

  @override
  State<ExportAnalyticsScreen> createState() => _ExportAnalyticsScreenState();
}

class _ExportAnalyticsScreenState extends State<ExportAnalyticsScreen> {
  final GlobalKey _previewKey = GlobalKey();

  Future<void> _exportPdf() async {
    final AnalyticsCubit cubit = context.read<AnalyticsCubit>();
    final bool success = await cubit.exportDashboardAsPdf();
    if (!mounted) return;
    context.showSnackBar(
      success ? 'تم فتح ملف PDF للطباعة/الحفظ.' : 'تعذّر تصدير ملف PDF.',
    );
  }

  Future<void> _exportImage() async {
    final AnalyticsCubit cubit = context.read<AnalyticsCubit>();
    try {
      final RenderRepaintBoundary boundary = _previewKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('تعذّر ترميز الصورة.');

      final bool success = await cubit.exportSectionAsImage(
        pngBytes: byteData.buffer.asUint8List(),
        fileName:
            'avahi-analytics-${DateFormatter.shortDate(DateTime.now())}.png',
      );
      if (!mounted) return;
      context.showSnackBar(
        success ? 'تم تنزيل صورة اللوحة.' : 'تعذّر تصدير الصورة.',
      );
    } catch (_) {
      if (!mounted) return;
      context.showSnackBar('تعذّر تصدير الصورة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticsData data = widget.data;
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'معاينة اللوحة قبل التصدير — '
                  '${DateFormatter.longDate(data.rangeFrom)} إلى '
                  '${DateFormatter.longDate(data.rangeTo)}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AvahiButton(
                  label: 'تصدير PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  isLoading: widget.isExporting,
                  onPressed: widget.isExporting ? null : _exportPdf,
                ),
              ),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: AvahiButton(
                  label: 'تصدير صورة',
                  icon: Icons.image_outlined,
                  variant: AvahiButtonVariant.secondary,
                  isLoading: widget.isExporting,
                  onPressed: widget.isExporting ? null : _exportImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.lg),
          RepaintBoundary(
            key: _previewKey,
            child: Container(
              padding: const EdgeInsets.all(AvahiSpacing.md),
              color: colors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'لوحة التحليلات التنفيذية',
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AvahiSpacing.md),
                  KpiSummaryRow(data: data),
                  const SizedBox(height: AvahiSpacing.lg),
                  SectionCard(
                    title: 'تقدّم المشاريع',
                    child: ProjectProgressChart(
                      projects: data.projectProgressList,
                    ),
                  ),
                  const SizedBox(height: AvahiSpacing.md),
                  SectionCard(
                    title: 'توزيع حالات المهام',
                    child: TaskDistributionChart(
                      distribution: data.taskStatusDistribution,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
