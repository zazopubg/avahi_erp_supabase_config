import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/permissions.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/punch_item.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/punch_cubit.dart';
import '../../state/punch_state.dart';
import '../../widgets/punch_close_form.dart';
import '../../widgets/punch_item_card.dart';
import '../../widgets/task_priority_selector_items.dart';

/// لوحة إدارة/معالجة عنصر ملاحظات جانبية لسطح المكتب — النظير المباشر
/// لـ `punch_item_details.dart` (الهاتف)، لكن كلوحة ثابتة ضمن تخطيط
/// `punch_dashboard.dart` ثنائي الأعمدة (بنفس نمط `TaskDetailsPanel`،
/// `features/tasks/presentation/screens/desktop/task_details_panel.dart`)
/// بدل صفحة كاملة منفصلة.
///
/// يقرأ [itemId] فقط ويحلّه في كل مرة من `PunchData.dashboardItems`
/// الحالية (وليس كائن [PunchItem] ثابتاً) كي تعكس اللوحة أي تحديث
/// فوري (إغلاق ناجح مثلاً) دون إعادة اختيار الصف يدوياً في الجدول —
/// نفس منطق `TaskDetailsPanel._resolve` تماماً.
class PunchItemManage extends StatelessWidget {
  const PunchItemManage({required this.itemId, super.key, this.onClose});

  final String? itemId;
  final VoidCallback? onClose;

  PunchItem? _resolve(PunchData data) {
    if (itemId == null) return null;
    return data.dashboardItems
        .cast<PunchItem?>()
        .firstWhere((PunchItem? i) => i?.id == itemId, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return BlocBuilder<PunchCubit, PunchState>(
      builder: (BuildContext context, PunchState state) {
        final PunchData? data = state.dataOrNull;
        final PunchItem? item = data != null ? _resolve(data) : null;

        return Container(
          width: 380,
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(left: BorderSide(color: colors.outlineVariant)),
          ),
          child: item == null
              ? Center(
                  child: Text(
                    'اختر عنصراً لعرض تفاصيله وإدارته',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : _ManageContent(item: item, onClose: onClose),
        );
      },
    );
  }
}

class _ManageContent extends StatelessWidget {
  const _ManageContent({required this.item, this.onClose});

  final PunchItem item;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(item.title, style: context.textTheme.titleLarge),
              ),
              if (onClose != null)
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Wrap(
            spacing: AvahiSpacing.xs,
            children: <Widget>[
              PunchStatusBadge(status: item.status),
              Chip(label: Text(punchPriorityLabelAr(item.priority))),
            ],
          ),
          if (item.description != null &&
              item.description!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AvahiSpacing.lg),
            Text('الوصف', style: context.textTheme.titleSmall),
            const SizedBox(height: AvahiSpacing.xs),
            Text(item.description!),
          ],
          if (item.locationNote != null &&
              item.locationNote!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AvahiSpacing.lg),
            Text('الموقع', style: context.textTheme.titleSmall),
            const SizedBox(height: AvahiSpacing.xs),
            Text(item.locationNote!),
          ],
          const SizedBox(height: AvahiSpacing.lg),
          Text('التاريخ', style: context.textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.xs),
          Text(
            'أُنشئ في ${DateFormatter.dateTime(item.createdAt)}',
            style: context.textTheme.bodySmall,
          ),
          if (item.dueDate != null)
            Text(
              'الاستحقاق: ${DateFormatter.shortDate(item.dueDate!)}',
              style: context.textTheme.bodySmall,
            ),
          if (item.closedAt != null)
            Text(
              'أُغلق في ${DateFormatter.dateTime(item.closedAt!)}',
              style: context.textTheme.bodySmall,
            ),
          const SizedBox(height: AvahiSpacing.xl),
          if (!item.status.isClosed)
            BlocBuilder<AuthCubit, AuthState>(
              builder: (BuildContext context, AuthState authState) {
                final AppUser? user = authState.maybeWhen<AppUser?>(
                  orElse: () => null,
                  authenticated: (AppUser u, _) => u,
                );
                final bool canClose = user != null &&
                    RolePermissions.has(user.role, Permission.punchListCloseOut);
                if (!canClose) {
                  return Text(
                    'لا تملك صلاحية إغلاق عناصر الملاحظات.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  );
                }
                return PunchCloseForm(item: item);
              },
            ),
        ],
      ),
    );
  }
}
