import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/permissions.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/punch_item.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/punch_cubit.dart';
import '../../state/punch_state.dart';
import '../../widgets/punch_close_form.dart';
import '../../widgets/punch_item_card.dart';
import '../../widgets/task_priority_selector_items.dart';

/// حزمة وسيطة (Args) تُمرَّر عبر `extra:` لمسار
/// `RouteNames.punchListDetails` (`/punch-list/details`) — تحمل
/// [PunchItem] نفسه (بدل جلبه من جديد بمعرّف، إذ لا يوجد UseCase
/// "جلب عنصر واحد بمعرّفه" ضمن نطاق Prompt 19) **و**نسخة [PunchCubit]
/// الحيّة نفسها التي فتحت الشاشة (من `punch_list_screen.dart` أو
/// `punch_dashboard.dart`)، بنفس نمط `PhotoAttachRouteArgs`
/// (`features/photos/presentation/screens/mobile/photo_attach_screen.dart`)
/// تماماً — يضمن أن إغلاق العنصر هنا ينعكس فوراً على نفس القائمة
/// خلف هذه الشاشة عند العودة إليها (بخلاف `PunchItemCreateScreen`
/// المستقلة عمداً، انظر توثيقها).
class PunchItemDetailsRouteArgs {
  const PunchItemDetailsRouteArgs({required this.item, required this.cubit});

  final PunchItem item;
  final PunchCubit cubit;
}

/// شاشة تفاصيل عنصر ملاحظات كاملة (الهاتف) — العنوان والوصف والحالة
/// والأولوية وموقع الملاحظة النصي وتاريخ الإنشاء/الاستحقاق، مع زر
/// إغلاق رسمي (`punch_close_form.dart`) يظهر فقط لمن يملك
/// [Permission.punchListCloseOut] وطالما العنصر غير مُغلق أصلاً.
///
/// تفترض وجود `BlocProvider<PunchCubit>` مزوَّد مسبقاً من الشجرة
/// الأعلى (إما محلياً عبر `Navigator.push` من `punch_list_screen.dart`،
/// أو عبر `BlocProvider<PunchCubit>.value` في `app_router.dart` عند
/// الوصول لمسار `/punch-list/details` مباشرة) — لا تُنشئ نسخة خاصة بها.
class PunchItemDetailsScreen extends StatelessWidget {
  const PunchItemDetailsScreen({required this.item, super.key});

  final PunchItem item;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (BuildContext context, PunchState state) {
        // العنصر الأحدث من قائمة الـ Cubit إن كان لا يزال موجوداً بها
        // (مثال: بعد إغلاقه للتو)، وإلا يُعرض [item] الأصلي كما وصل.
        final PunchItem current = state.dataOrNull?.items.firstWhere(
              (PunchItem i) => i.id == item.id,
              orElse: () => item,
            ) ??
            item;

        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل عنصر الملاحظات')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(current.title, style: context.textTheme.headlineSmall),
                const SizedBox(height: AvahiSpacing.sm),
                Wrap(
                  spacing: AvahiSpacing.xs,
                  runSpacing: AvahiSpacing.xs,
                  children: <Widget>[
                    PunchStatusBadge(status: current.status),
                    Chip(
                      label: Text(punchPriorityLabelAr(current.priority)),
                    ),
                  ],
                ),
                if (current.description != null &&
                    current.description!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AvahiSpacing.lg),
                  Text('الوصف', style: context.textTheme.titleSmall),
                  const SizedBox(height: AvahiSpacing.xs),
                  Text(current.description!),
                ],
                if (current.locationNote != null &&
                    current.locationNote!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AvahiSpacing.lg),
                  Text('الموقع', style: context.textTheme.titleSmall),
                  const SizedBox(height: AvahiSpacing.xs),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AvahiSpacing.xs),
                      Expanded(child: Text(current.locationNote!)),
                    ],
                  ),
                ],
                const SizedBox(height: AvahiSpacing.lg),
                Text('التاريخ', style: context.textTheme.titleSmall),
                const SizedBox(height: AvahiSpacing.xs),
                _DateRow(label: 'أُنشئ في', date: current.createdAt),
                if (current.dueDate != null)
                  _DateRow(label: 'تاريخ الاستحقاق', date: current.dueDate),
                if (current.resolvedAt != null)
                  _DateRow(label: 'عولج في', date: current.resolvedAt),
                if (current.closedAt != null)
                  _DateRow(label: 'أُغلق في', date: current.closedAt),
                const SizedBox(height: AvahiSpacing.xl),
                if (!current.status.isClosed)
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (BuildContext context, AuthState authState) {
                      final AppUser? user = authState.maybeWhen<AppUser?>(
                        orElse: () => null,
                        authenticated: (AppUser u, _) => u,
                      );
                      final bool canClose = user != null &&
                          RolePermissions.has(
                            user.role,
                            Permission.punchListCloseOut,
                          );
                      if (!canClose) return const SizedBox.shrink();
                      return AvahiButton(
                        label: 'إغلاق العنصر',
                        icon: Icons.check_circle_outline,
                        isFullWidth: true,
                        onPressed: () => PunchCloseForm.show(
                          context,
                          item: current,
                          onClosed: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.date});

  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
      child: Row(
        children: <Widget>[
          Text('$label: ', style: context.textTheme.bodySmall),
          Text(
            DateFormatter.dateTime(date!),
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
