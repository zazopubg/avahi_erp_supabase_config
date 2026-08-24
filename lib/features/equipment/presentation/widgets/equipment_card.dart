import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import 'equipment_status_badge.dart';

/// بطاقة معدة مضغوطة — أيقونة نوعية، الاسم، شارة الحالة، ساعات
/// التشغيل التراكمية، اسم المشروع المرتبط (إن وُجد)، وموعد الصيانة
/// القادم (إن اقترب أو تجاوز) — العنصر البصري المشترك بين
/// `my_equipment_screen.dart` (الهاتف) و`equipment_registry.dart`/
/// `maintenance_schedule.dart` (سطح المكتب)، بنفس فلسفة `DocumentCard`.
///
/// مكوّن عرض بحت — [onTap] اختياري لفتح `equipment_details.dart` أو
/// الانتقال لتسجيل ساعات تشغيل.
class EquipmentCard extends StatelessWidget {
  const EquipmentCard({
    required this.equipment,
    super.key,
    this.onTap,
    this.projectLabel,
    this.trailing,
    this.showMaintenanceDue = false,
  });

  final Equipment equipment;
  final VoidCallback? onTap;

  /// اسم المشروع المرتبط — `null` لمعدة غير مسندة لمشروع حالياً.
  final String? projectLabel;

  /// عنصر إجراءات اختياري يُعرض في نهاية البطاقة (مثال: زر "إسناد"
  /// في `equipment_registry.dart`، أو زر "تسجيل ساعات" في
  /// `my_equipment_screen.dart`).
  final Widget? trailing;

  /// عند `true` يُبرز موعد الصيانة القادم بلون تحذيري/خطر حسب اقترابه
  /// — `maintenance_schedule.dart` فقط.
  final bool showMaintenanceDue;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool overdue = equipment.nextMaintenanceDue != null &&
        equipment.nextMaintenanceDue!.isBefore(DateTime.now());

    return Material(
      color: context.colors.surface,
      borderRadius: AvahiRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AvahiRadius.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(AvahiSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AvahiRadius.radiusMd,
            border: Border.all(
              color: (showMaintenanceDue && overdue)
                  ? colors.danger
                  : colors.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.12),
                  borderRadius: AvahiRadius.radiusSm,
                ),
                child: Icon(
                  Icons.construction_outlined,
                  color: colors.brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      equipment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Wrap(
                      spacing: AvahiSpacing.xs,
                      runSpacing: AvahiSpacing.xxs,
                      children: <Widget>[
                        EquipmentStatusBadge(status: equipment.status, dense: true),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            equipment.type,
                            style: context.textTheme.labelSmall,
                          ),
                        ),
                        if (projectLabel != null)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.apartment, size: 14),
                            label: Text(
                              projectLabel!,
                              style: context.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.timelapse_outlined,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AvahiSpacing.xxs),
                        Text(
                          '${NumberFormatter.decimal(equipment.usageHours)} ساعة تشغيل',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (showMaintenanceDue &&
                            equipment.nextMaintenanceDue != null) ...<Widget>[
                          const SizedBox(width: AvahiSpacing.xs),
                          Text('•', style: TextStyle(color: colors.onSurfaceVariant)),
                          const SizedBox(width: AvahiSpacing.xs),
                          Icon(
                            Icons.event_outlined,
                            size: 14,
                            color: overdue ? colors.danger : colors.warning,
                          ),
                          const SizedBox(width: AvahiSpacing.xxs),
                          Text(
                            overdue
                                ? 'متأخرة منذ ${DateFormatter.shortDate(equipment.nextMaintenanceDue!)}'
                                : 'صيانة مستحقة ${DateFormatter.shortDate(equipment.nextMaintenanceDue!)}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: overdue ? colors.danger : colors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AvahiSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
