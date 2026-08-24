import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// مُدخل عدد العمّال الحاضرين في التقرير — عدّاد رقمي بأزرار +/- مع
/// إمكانية الكتابة المباشرة، بدل حقل نصي خام (عدد صحيح غير سالب دوماً،
/// أكثر ملاءمة لإدخال سريع بالهاتف من موقع عمل).
class LaborCountInput extends StatelessWidget {
  const LaborCountInput({required this.count, required this.onChanged, super.key});

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('عدد العمّال', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AvahiSpacing.xxs),
              Text(
                'عدد العمّال الحاضرين في الموقع خلال هذا التقرير',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.xxs),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: AvahiRadius.radiusMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: 'إنقاص',
                onPressed: count > 0 ? () => onChanged(count - 1) : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'زيادة',
                onPressed: () => onChanged(count + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
