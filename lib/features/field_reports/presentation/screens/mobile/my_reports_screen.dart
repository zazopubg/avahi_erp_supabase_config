import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/field_report.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/report_form_cubit.dart';
import '../../state/report_form_state.dart';
import '../../widgets/report_card.dart';
import 'report_form_screen.dart';
import 'report_preview_screen.dart';

/// تبويب "تقاريري" — كل تقارير المستخدم الحالي ضمن مشروعه (كل الحالات)
/// مرتّبة تنازلياً حسب التاريخ. تُحمَّل عبر [ReportFormCubit.loadMyReports]
/// (تلقائياً عند [ReportFormCubit.loadInitial]، ويدوياً هنا عبر
/// السحب للتحديث). النقر على مسوّدة يفتح [ReportFormScreen] للاستكمال؛
/// أي حالة أخرى تفتح [ReportPreviewScreen] للاطلاع فقط.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportFormCubit, ReportFormState>(
      builder: (BuildContext context, ReportFormState state) {
        final ReportFormData? data = state.dataOrNull;
        if (data == null) return const LoadingIndicator();

        if (data.isMyReportsLoading && data.myReports.isEmpty) {
          return const LoadingIndicator(label: 'جارٍ تحميل تقاريرك...');
        }

        if (data.myReports.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'لا توجد تقارير بعد',
            message: 'اضغط على "تقرير جديد" لإنشاء أول تقرير ميداني.',
          );
        }

        final List<FieldReport> sorted = List<FieldReport>.of(data.myReports)
          ..sort((FieldReport a, FieldReport b) => b.reportDate.compareTo(a.reportDate));

        return RefreshIndicator(
          onRefresh: () => context.read<ReportFormCubit>().loadMyReports(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AvahiSpacing.md,
              AvahiSpacing.md,
              AvahiSpacing.md,
              96,
            ),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final FieldReport report = sorted[index];
              return ReportCard(
                report: report,
                onTap: () async {
                  await context.read<ReportFormCubit>().resumeExisting(report);
                  if (!context.mounted) return;
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => report.status.isDraft
                          ? const ReportFormScreen()
                          : const ReportPreviewScreen(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
