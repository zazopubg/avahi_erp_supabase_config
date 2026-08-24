import 'package:flutter/material.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/document.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../state/documents_state.dart';
import '../../widgets/document_card.dart';

/// عرض المستندات مُجمَّعة حسب [Document.category] — نمط عرض بديل ضمن
/// `documents_manager.dart` (زر تبديل "قائمة" / "حسب التصنيف" في
/// شريطها العلوي)، يعتمد [DocumentsData.documentsByCategory] مباشرة
/// (مبني فوق [DocumentsData.filteredDocuments] — يحترم فلاتر البحث/
/// النطاق/الأرشفة الحالية نفسها).
///
/// مكوّن عرض بحت — [onDocumentTap] يُربط بفتح `document_viewer.dart`،
/// بنفس دور `onTap` في [DocumentCard] العادية.
class DocumentCategories extends StatelessWidget {
  const DocumentCategories({
    required this.data,
    super.key,
    this.onDocumentTap,
  });

  final DocumentsData data;
  final ValueChanged<Document>? onDocumentTap;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Document>> grouped = data.documentsByCategory;

    if (grouped.isEmpty) {
      return const EmptyState(
        title: 'لا توجد مستندات مطابقة',
        message: 'جرّب تعديل معايير التصفية أو رفع مستند جديد.',
        icon: Icons.folder_off_outlined,
      );
    }

    final List<String> orderedCategories = <String>[
      // نفس ترتيب [kDocumentCategories] الثابت أولاً، ثم أي تصنيفات
      // نصية حرة أخرى غير مدرجة ضمنها (مستندات قديمة بتصنيف مخصص)،
      // و"بلا تصنيف" أخيراً دوماً.
      for (final String category in kDocumentCategories)
        if (grouped.containsKey(category)) category,
      for (final String category in grouped.keys)
        if (!kDocumentCategories.contains(category) && category != 'بلا تصنيف')
          category,
      if (grouped.containsKey('بلا تصنيف')) 'بلا تصنيف',
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      itemCount: orderedCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final String category = orderedCategories[index];
        final List<Document> documents = grouped[category]!;
        return _CategorySection(
          category: category,
          documents: documents,
          projectsById: data.projectsById,
          onDocumentTap: onDocumentTap,
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.documents,
    required this.projectsById,
    this.onDocumentTap,
  });

  final String category;
  final List<Document> documents;
  final Map<String, Project> projectsById;
  final ValueChanged<Document>? onDocumentTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // إزالة الخط الفاصل الافتراضي لـ ExpansionTile كي تندمج بصرياً
      // مع بقية بطاقات الشاشة (بنفس نمط تخصيصات `avahi_theme.dart`
      // الأخرى للمكوّنات الجاهزة من Material).
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: <Widget>[
            Text(category, style: context.textTheme.titleSmall),
            const SizedBox(width: AvahiSpacing.xs),
            Text(
              '(${documents.length})',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: <Widget>[
          for (final Document document in documents)
            Padding(
              padding: const EdgeInsets.only(bottom: AvahiSpacing.sm),
              child: DocumentCard(
                document: document,
                projectLabel: document.projectId == null
                    ? null
                    : projectsById[document.projectId]?.name,
                onTap: () => onDocumentTap?.call(document),
              ),
            ),
        ],
      ),
    );
  }
}
