import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../state/report_form_cubit.dart';
import 'my_reports_screen.dart';
import 'report_drafts_screen.dart';
import 'report_form_screen.dart';

/// مضيف تبويبات التقارير الميدانية لدور "العامل الميداني" (عرض هاتف،
/// `ShellMode.mobile`) — تبويبان محليان عبر [IndexedStack] +
/// [NavigationBar] سفلي: "مسوّداتي" ([ReportDraftsScreen]) و"تقاريري"
/// ([MyReportsScreen])، بنفس نمط `AttendanceMobileHome`. زر إنشاء تقرير
/// عائم (`FloatingActionButton`) ثابت عبر التبويبين معاً — يستدعي
/// [ReportFormCubit.startNewDraft] ثم يفتح [ReportFormScreen] فوراً.
class FieldReportsMobileHome extends StatefulWidget {
  const FieldReportsMobileHome({super.key});

  @override
  State<FieldReportsMobileHome> createState() => _FieldReportsMobileHomeState();
}

class _FieldReportsMobileHomeState extends State<FieldReportsMobileHome> {
  int _index = 0;

  static const List<Widget> _tabs = <Widget>[
    ReportDraftsScreen(),
    MyReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير الميدانية')),
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewReport(context),
        icon: const Icon(Icons.add),
        label: const Text('تقرير جديد'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), label: 'مسوّداتي'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'تقاريري'),
        ],
      ),
    );
  }

  void _startNewReport(BuildContext context) {
    context.read<ReportFormCubit>().startNewDraft();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ReportFormScreen()),
    );
  }
}
