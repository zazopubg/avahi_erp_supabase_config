import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../domain/entities/document.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// يحوّل امتداد ملف مستند إلى أيقونة ولون دلالي مناسبين — منطق مشترك
/// بين [DocumentCard] وبطاقة `document_viewer.dart` (سطح المكتب).
(IconData, Color) documentFileVisuals(AvahiColors colors, String? fileType) {
  switch ((fileType ?? '').toLowerCase()) {
    case 'pdf':
      return (Icons.picture_as_pdf_outlined, colors.danger);
    case 'doc':
    case 'docx':
      return (Icons.description_outlined, colors.info);
    case 'xls':
    case 'xlsx':
      return (Icons.table_chart_outlined, colors.success);
    case 'ppt':
    case 'pptx':
      return (Icons.slideshow_outlined, colors.warning);
    default:
      return (Icons.insert_drive_file_outlined, colors.onSurfaceVariant);
  }
}

/// بطاقة مستند مضغوطة — أيقونة نوع الملف، العنوان، التصنيف، حجم
/// الملف، رقم الإصدار (عند تجاوز 1)، وحالة الأرشفة إن أُرشف — العنصر
/// البصري المشترك بين `documents_list.dart` (الهاتف) و
/// `documents_manager.dart`/`document_categories.dart` (سطح المكتب)،
/// بنفس فلسفة `PunchItemCard`.
///
/// مكوّن عرض بحت — [onTap] اختياري لفتح `document_viewer.dart` أو
/// معاينة مباشرة.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    required this.document,
    super.key,
    this.onTap,
    this.projectLabel,
    this.trailing,
  });

  final Document document;
  final VoidCallback? onTap;

  /// اسم المشروع المرتبط — يظهر فقط ضمن `documents_manager.dart` عند
  /// عرض نطاق "الكل" (عدة مشاريع معاً)، أو `null` لمستند عام على
  /// مستوى الشركة أو عند عرض نطاق مشروع واحد معروف أصلاً من السياق.
  final String? projectLabel;

  /// عنصر إجراءات اختياري يُعرض في نهاية البطاقة (مثال: زر أرشفة في
  /// `documents_manager.dart`).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final (IconData icon, Color iconColor) = documentFileVisuals(
      colors,
      document.fileType,
    );

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
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AvahiRadius.radiusSm,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Wrap(
                      spacing: AvahiSpacing.xs,
                      runSpacing: AvahiSpacing.xxs,
                      children: <Widget>[
                        if (document.category != null)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              document.category!,
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
                        if (document.version > 1)
                          StatusBadge(
                            label: 'إصدار ${document.version}',
                            status: AvahiStatus.info,
                            dense: true,
                          ),
                        if (document.isArchived)
                          const StatusBadge(
                            label: 'مؤرشف',
                            status: AvahiStatus.neutral,
                            icon: Icons.archive_outlined,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Row(
                      children: <Widget>[
                        if (document.fileSizeBytes != null) ...<Widget>[
                          Text(
                            NumberFormatter.fileSize(document.fileSizeBytes!),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AvahiSpacing.xs),
                          Text(
                            '•',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AvahiSpacing.xs),
                        ],
                        Text(
                          DateFormatter.relative(document.createdAt),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
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
