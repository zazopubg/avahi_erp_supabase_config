import 'package:flutter/material.dart';

import '../../../../../domain/entities/app_user.dart';
import 'check_in_screen.dart';
import 'my_history_screen.dart';
import 'today_summary_screen.dart';

/// مضيف تبويبات الحضور لدور العامل الميداني (عرض هاتف، `ShellMode.mobile`)
/// — تبويبان محليان عبر [IndexedStack] + [NavigationBar] سفلي: "الدخول"
/// ([CheckInScreen]) و"سجلي" ([MyHistoryScreen]). تنقّل محلي بالكامل
/// (بلا أي مسارات `go_router` إضافية) — انظر توثيق القرار في
/// `attendance_cubit.dart`.
///
/// زر "التفاصيل" في شريط العنوان (معروض فقط ضمن تبويب "الدخول") يفتح
/// `today_summary_screen.dart` عبر `Navigator.push`.
class AttendanceMobileHome extends StatefulWidget {
  const AttendanceMobileHome({required this.user, super.key});

  final AppUser user;

  @override
  State<AttendanceMobileHome> createState() => _AttendanceMobileHomeState();
}

class _AttendanceMobileHomeState extends State<AttendanceMobileHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحضور والانصراف'),
        actions: <Widget>[
          if (_index == 0)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'تفاصيل حضور اليوم',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const TodaySummaryScreen()),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          CheckInScreen(user: widget.user),
          MyHistoryScreen(user: widget.user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.login), label: 'الدخول'),
          NavigationDestination(icon: Icon(Icons.history), label: 'سجلي'),
        ],
      ),
    );
  }
}
