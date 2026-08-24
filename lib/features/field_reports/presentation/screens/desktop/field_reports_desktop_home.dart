import 'package:flutter/material.dart';

import 'report_export_screen.dart';
import 'reports_archive.dart';
import 'reports_inbox.dart';

/// مضيف تبويبات التقارير الميدانية لدور "الإدارة" (سطح مكتب/لوحي مع
/// صلاحية [Permission.fieldReportsViewTeam])، بنفس نمط
/// `AttendanceDesktopHome`: ثلاثة تبويبات ثابتة أعلى الشاشة — "الوارد"
/// ([ReportsInbox])، "الأرشيف" ([ReportsArchive])، و"تصدير"
/// ([ReportExportScreen]) — تشترك جميعها نفس نسخة `ReportsInboxCubit`
/// المُوفَّرة أعلاها في `field_reports_screen.dart`.
class FieldReportsDesktopHome extends StatelessWidget {
  const FieldReportsDesktopHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير الميدانية'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.inbox_outlined), text: 'الوارد'),
              Tab(icon: Icon(Icons.archive_outlined), text: 'الأرشيف'),
              Tab(icon: Icon(Icons.file_download_outlined), text: 'تصدير'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            ReportsInbox(),
            ReportsArchive(),
            ReportExportScreen(),
          ],
        ),
      ),
    );
  }
}
