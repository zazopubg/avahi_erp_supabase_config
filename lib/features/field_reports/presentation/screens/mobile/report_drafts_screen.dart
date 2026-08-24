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

/// تبويب "مسوّداتي" — تقارير [ReportFormData.draftReports] فقط
/// (`status == draft`)، للاستكمال السريع. النقر يستأنف المسوّدة عبر
/// [ReportFormCubit.resumeExisting] ثم يفتح [ReportFormScreen] مباشرة.
class ReportDraftsScreen extends StatelessWidget {
  const ReportDraftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportFormCubit, ReportFormState>(
      builder: (BuildContext context, ReportFormState state) {
        final ReportFormData? data = state.dataOrNull;
        if (data == null) return const LoadingIndicator();

        if (data.isMyReportsLoading && data.myReports.isEmpty) {
          return const LoadingIndicator(label: 'جارٍ تحميل المسوّدات...');
        }

        final List<FieldReport> drafts = data.draftReports;

        if (drafts.isEmpty) {
          return const EmptyState(
            icon: Icons.edit_note_outlined,
            title: 'لا توجد مسوّدات',
            message: 'كل تقاريرك مُقدَّمة بالكامل، أو لم تبدأ أي تقرير بعد.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<ReportFormCubit>().loadMyReports(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AvahiSpacing.md,
              AvahiSpacing.md,
              AvahiSpacing.md,
              96,
            ),
            itemCount: drafts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final FieldReport draft = drafts[index];
              return ReportCard(
                report: draft,
                onTap: () async {
                  await context.read<ReportFormCubit>().resumeExisting(draft);
                  if (!context.mounted) return;
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => const ReportFormScreen()),
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
