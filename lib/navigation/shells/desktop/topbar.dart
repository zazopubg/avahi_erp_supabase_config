import 'package:flutter/material.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../ui/theme/avahi_spacing.dart';
import 'notification_panel.dart';

/// الشريط العلوي الثابت لقالب سطح المكتب (`DesktopShell`) — حقل بحث
/// عام (بلا منطق بحث فعلي بعد؛ كل ميزة `features/` ستربط بحثها
/// المحلي/السحابي الخاص بها لاحقاً) + زر جرس يفتح [NotificationPanel]
/// (Placeholder، `features/notifications/` Prompt 23).
///
/// مكوّن عرض بحت — لا يحمل أي حالة بحث أو إشعارات فعلية بنفسه.
class Topbar extends StatelessWidget implements PreferredSizeWidget {
  const Topbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
      color: context.colors.surface,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _SearchField(),
            ),
          ),
          const SizedBox(width: AvahiSpacing.md),
          Builder(
            builder: (BuildContext anchorContext) => IconButton(
              tooltip: 'الإشعارات',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => NotificationPanel.show(anchorContext),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 20),
        hintText: 'بحث...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
