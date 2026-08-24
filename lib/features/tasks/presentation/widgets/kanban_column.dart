import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import 'task_card.dart';
import 'task_status_chip.dart';

/// عمود واحد ضمن لوحة Kanban (`tasks_board_screen.dart`) — يمثّل حالة
/// [status] واحدة، يعرض [tasks] كبطاقات [TaskCard] قابلة للسحب
/// (`LongPressDraggable`)، ويعمل هو نفسه كـ [DragTarget] يستقبل أي
/// بطاقة مسحوبة من عمود آخر: عند الإفلات، يستدعي [onTaskDropped]
/// بالمهمة المُفلَتة والفهرس المستهدف ضمن هذا العمود تحديداً (لضبط
/// `Task.kanbanOrder` الجديد)، تاركاً تنفيذ التحديث التفاؤلي الفعلي
/// لـ `TasksCubit.updateStatus` (`tasks_board_screen.dart` هو من
/// يستدعيها).
///
/// مكوّن عرض بحت — لا يستدعي أي `Cubit`/UseCase بنفسه.
class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    required this.status,
    required this.tasks,
    required this.onTaskDropped,
    super.key,
    this.onTaskTap,
    this.width = 280,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final double width;

  final void Function(Task task, int targetIndex) onTaskDropped;
  final ValueChanged<Task>? onTaskTap;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return DragTarget<Task>(
      // يقبل أي مهمة مسحوبة دائماً — سواء أتت من عمود آخر (تغيير
      // حالة) أو من هذا العمود نفسه (إعادة ترتيب داخلي)، وتُفلَت هنا
      // في نهاية العمود تحديداً (`tasks.length` كفهرس مستهدف)؛ الإفلات
      // فوق بطاقة محددة داخل العمود يُلتقط بدلاً من ذلك عبر
      // `_DraggableTaskCard` (`DragTarget` أصغر لكل بطاقة).
      onWillAcceptWithDetails: (DragTargetDetails<Task> details) => true,
      onAcceptWithDetails: (DragTargetDetails<Task> details) {
        onTaskDropped(details.data, tasks.length);
      },
      builder: (BuildContext context, List<Task?> candidates, List<dynamic> rejects) {
        final bool isHovering = candidates.isNotEmpty;

        return SizedBox(
          width: width,
          child: Container(
            decoration: BoxDecoration(
              color: isHovering
                  ? colors.brandContainer.withValues(alpha: 0.3)
                  : colors.surfaceVariant.withValues(alpha: 0.4),
              borderRadius: AvahiRadius.radiusMd,
              border: Border.all(
                color: isHovering ? colors.brand : colors.outlineVariant,
                width: isHovering ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AvahiSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AvahiSpacing.xs,
                    vertical: AvahiSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: TaskStatusChip(status: status)),
                      const SizedBox(width: AvahiSpacing.xxs),
                      Text(
                        '${tasks.length}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tasks.isEmpty
                      ? const EmptyState(
                          title: 'لا توجد مهام هنا',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            vertical: AvahiSpacing.xs,
                          ),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AvahiSpacing.xs),
                          itemBuilder: (BuildContext context, int index) {
                            final Task task = tasks[index];
                            return _DraggableTaskCard(
                              task: task,
                              index: index,
                              onTaskTap: onTaskTap,
                              onDroppedAt: onTaskDropped,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// بطاقة مهمة واحدة قابلة للسحب ضمن عمود، ملفوفة أيضاً بـ [DragTarget]
/// خاص بها بحيث يمكن إفلات بطاقة أخرى *فوقها تحديداً* لضبط ترتيب دقيق
/// ضمن نفس العمود (وليس فقط في نهايته).
class _DraggableTaskCard extends StatelessWidget {
  const _DraggableTaskCard({
    required this.task,
    required this.index,
    required this.onDroppedAt,
    this.onTaskTap,
  });

  final Task task;
  final int index;
  final ValueChanged<Task>? onTaskTap;
  final void Function(Task task, int targetIndex) onDroppedAt;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (DragTargetDetails<Task> details) =>
          details.data.id != task.id,
      onAcceptWithDetails: (DragTargetDetails<Task> details) {
        onDroppedAt(details.data, index);
      },
      builder: (BuildContext context, List<Task?> candidates, List<dynamic> rejects) {
        return LongPressDraggable<Task>(
          data: task,
          feedback: SizedBox(
            width: 260,
            child: TaskCard(task: task, showStatus: true),
          ),
          childWhenDragging: TaskCard(task: task, isDragging: true),
          child: TaskCard(
            task: task,
            onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
          ),
        );
      },
    );
  }
}
