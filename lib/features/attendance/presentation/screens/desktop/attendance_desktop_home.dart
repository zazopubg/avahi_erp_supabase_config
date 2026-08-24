import 'package:flutter/material.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../mobile/check_in_screen.dart';
import 'attendance_monitor.dart';
import 'attendance_report.dart';

/// مضيف عرض ميزة الحضور على سطح المكتب/الجهاز اللوحي — يتفرّع حسب
/// [canApproveTeam] (صلاحية [Permission.attendanceApproveTeam] للدور
/// الحالي، مُحسَّبة في `attendance_screen.dart`):
/// - `true` (مشرف/رئيس عمال/مدير مشروع): تبويبان "المراقبة اللحظية"
///   ([AttendanceMonitor]) و"التقرير الشهري" ([AttendanceReport] —
///   يضمّ [AttendanceTable] داخلياً).
/// - `false` (عامل ميداني يفتح التطبيق من سطح المكتب): بطاقة تسجيل
///   حضور مبسّطة تُعيد استخدام [CheckInScreen] نفسها (مكوّن عرض واحد
///   يعمل على أي عرض شاشة، إذ بُني بالكامل فوق `BlocBuilder` بلا أي
///   افتراض حول حجم الشاشة) ضمن حاوية بعرض أقصى محدود.
class AttendanceDesktopHome extends StatelessWidget {
  const AttendanceDesktopHome({
    required this.user,
    required this.canApproveTeam,
    super.key,
  });

  final AppUser user;
  final bool canApproveTeam;

  @override
  Widget build(BuildContext context) {
    if (!canApproveTeam) {
      return Scaffold(
        appBar: AppBar(title: const Text('الحضور والانصراف')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AvahiSpacing.lg),
              child: CheckInScreen(user: user),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحضور والانصراف'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.sensors), text: 'المراقبة اللحظية'),
              Tab(icon: Icon(Icons.summarize), text: 'التقرير الشهري'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            AttendanceMonitor(user: user),
            const AttendanceReport(),
          ],
        ),
      ),
    );
  }
}
