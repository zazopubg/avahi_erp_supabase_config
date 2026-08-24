import 'package:flutter/material.dart';

import '../../theme/avahi_colors.dart';
import '../../theme/avahi_radius.dart';
import '../../theme/avahi_spacing.dart';
import '../common/empty_state.dart';

/// تعريف عمود واحد ضمن [DataGridRtl].
class DataGridColumn<T> {
  const DataGridColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = Alignment.centerRight,
  });

  /// عنوان العمود في رأس الجدول.
  final String label;

  /// يبني محتوى الخلية لعنصر بيانات واحد.
  final Widget Function(BuildContext context, T item) cellBuilder;

  /// الوزن النسبي لعرض العمود ضمن [Expanded] — أعمدة النص الطويل
  /// (مثال: الاسم) تُعطى `flex` أكبر من أعمدة القيم القصيرة (الحالة،
  /// الوقت).
  final int flex;

  final AlignmentGeometry alignment;
}

/// جدول بيانات عام (Generic) لواجهات سطح المكتب، باتجاه RTL كامل —
/// أول استخدام فعلي له من `features/attendance/desktop/attendance_table.dart`
/// (Prompt 15)، ومصمَّم للبقاء عاماً بالكامل (بلا أي معرفة بميزة
/// الحضور تحديداً) ليُعاد استخدامه لاحقاً من `features/tasks/`،
/// `features/projects/`، وغيرها من شاشات سطح المكتب الإدارية.
///
/// مكوّن عرض بحت — لا يحمل أي منطق فرز/تصفية/ترقيم صفحات (Pagination)؛
/// المستدعي يمرّر [rows] مُعدَّة مسبقاً بالترتيب المطلوب. عند فراغ
/// [rows] يُعرض [EmptyState] بدل جدول فارغ بلا سياق.
class DataGridRtl<T> extends StatelessWidget {
  const DataGridRtl({
    required this.columns,
    required this.rows,
    super.key,
    this.emptyTitle = 'لا توجد بيانات لعرضها',
    this.emptyIcon = Icons.table_rows_outlined,
    this.onRowTap,
    this.rowKeyOf,
  });

  final List<DataGridColumn<T>> columns;
  final List<T> rows;
  final String emptyTitle;
  final IconData emptyIcon;
  final void Function(T item)? onRowTap;

  /// مفتاح فريد اختياري لكل صف (مثال: `(r) => r.id`) — يحسّن أداء
  /// إعادة البناء ضمن [ListView.builder] عند تحديثات لحظية متكررة
  /// (Realtime)، كما في `attendance_monitor.dart`.
  final Object Function(T item)? rowKeyOf;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return EmptyState(title: emptyTitle, icon: emptyIcon);
    }

    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AvahiRadius.radiusMd,
          border: Border.all(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            _HeaderRow<T>(columns: columns, colors: colors),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: colors.outlineVariant),
                itemBuilder: (BuildContext context, int index) {
                  final T item = rows[index];
                  return _DataRow<T>(
                    key: rowKeyOf != null ? ValueKey<Object>(rowKeyOf!(item)) : null,
                    columns: columns,
                    item: item,
                    onTap: onRowTap != null ? () => onRowTap!(item) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow<T> extends StatelessWidget {
  const _HeaderRow({required this.columns, required this.colors});

  final List<DataGridColumn<T>> columns;
  final AvahiColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surfaceVariant,
      padding: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.sm,
        vertical: AvahiSpacing.xs,
      ),
      child: Row(
        children: columns
            .map(
              (DataGridColumn<T> column) => Expanded(
                flex: column.flex,
                child: Align(
                  alignment: column.alignment,
                  child: Text(
                    column.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DataRow<T> extends StatelessWidget {
  const _DataRow({required this.columns, required this.item, super.key, this.onTap});

  final List<DataGridColumn<T>> columns;
  final T item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AvahiSpacing.sm,
          vertical: AvahiSpacing.xs,
        ),
        child: Row(
          children: columns
              .map(
                (DataGridColumn<T> column) => Expanded(
                  flex: column.flex,
                  child: Align(
                    alignment: column.alignment,
                    child: column.cellBuilder(context, item),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
