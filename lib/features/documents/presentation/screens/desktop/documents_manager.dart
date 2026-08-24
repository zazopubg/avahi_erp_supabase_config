import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/permissions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/services/file_picker_service.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/document.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/documents_cubit.dart';
import '../../state/documents_state.dart';
import '../../widgets/document_card.dart';
import '../../widgets/document_filter_bar.dart';
import '../../widgets/document_scope_selector.dart';
import 'document_categories.dart';
import 'document_viewer.dart';

/// واجهة إدارة المستندات الكاملة لسطح المكتب — نظير `documents_list.dart`
/// (الهاتف، عرض فقط) لكن بصلاحيات كاملة (Engineer/PM/Admin حسب
/// [Permission.documentsUpload]/[Permission.documentsDeleteAny]):
/// اختيار نطاق (الكل/الشركة/مشروع محدد)، بحث وتصفية حسب التصنيف، عرض
/// كقائمة مسطّحة أو مُجمَّعة حسب التصنيف ([DocumentCategories])، رفع
/// مستندات جديدة، ولوحة تفاصيل/أرشفة/إصدار جديد جانبية
/// ([DocumentViewerPanel]) — تخطيط عمودين، بنفس نمط
/// `punch_dashboard.dart`.
///
/// تفترض وجود `BlocProvider<DocumentsCubit>` مزوَّد مسبقاً من الشجرة
/// الأعلى (`documents_list.dart` — نقطة الدخول الموحَّدة لمسار
/// `RouteNames.documents`، انظر توثيق القرار الكامل هناك).
class DocumentsManager extends StatelessWidget {
  const DocumentsManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (BuildContext context, DocumentsState state) {
        final AppUser? user =
            context.read<AuthCubit>().state.maybeWhen<AppUser?>(
                  orElse: () => null,
                  authenticated: (AppUser u, _) => u,
                );
        final bool canUpload = user != null &&
            RolePermissions.has(user.role, Permission.documentsUpload);

        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة المستندات'),
            actions: <Widget>[
              if (canUpload)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AvahiSpacing.sm,
                  ),
                  child: AvahiButton(
                    label: 'رفع مستند',
                    icon: Icons.upload_file_outlined,
                    onPressed: () => _openUploadDialog(context),
                  ),
                ),
            ],
          ),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل المستندات...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل المستندات',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser u, _) =>
                      context.read<DocumentsCubit>().loadInitial(u),
                );
              },
            ),
            loaded: (DocumentsData data) => _ManagerBody(data: data),
          ),
        );
      },
    );
  }

  Future<void> _openUploadDialog(BuildContext context) async {
    final DocumentsCubit cubit = context.read<DocumentsCubit>();
    final DocumentsData? data = cubit.state.dataOrNull;
    if (data == null) return;

    final PickedFile? file = await cubit.pickDocumentFile();
    if (file == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _UploadDialog(cubit: cubit, data: data, file: file),
    );
  }
}

class _ManagerBody extends StatefulWidget {
  const _ManagerBody({required this.data});

  final DocumentsData data;

  @override
  State<_ManagerBody> createState() => _ManagerBodyState();
}

enum _ViewMode { list, category }

class _ManagerBodyState extends State<_ManagerBody> {
  _ViewMode _viewMode = _ViewMode.list;

  @override
  Widget build(BuildContext context) {
    final DocumentsCubit cubit = context.read<DocumentsCubit>();
    final DocumentsData data = widget.data;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DocumentScopeSelector(
                        data: data,
                        onChanged: cubit.setScopeFilter,
                      ),
                    ),
                    const SizedBox(width: AvahiSpacing.sm),
                    SegmentedButton<_ViewMode>(
                      segments: const <ButtonSegment<_ViewMode>>[
                        ButtonSegment<_ViewMode>(
                          value: _ViewMode.list,
                          icon: Icon(Icons.view_list_outlined),
                          label: Text('قائمة'),
                        ),
                        ButtonSegment<_ViewMode>(
                          value: _ViewMode.category,
                          icon: Icon(Icons.category_outlined),
                          label: Text('حسب التصنيف'),
                        ),
                      ],
                      selected: <_ViewMode>{_viewMode},
                      onSelectionChanged: (Set<_ViewMode> selected) =>
                          setState(() => _viewMode = selected.first),
                    ),
                  ],
                ),
                const SizedBox(height: AvahiSpacing.sm),
                DocumentFilterBar(
                  data: data,
                  onCategoryChanged: cubit.setCategoryFilter,
                  onSearchChanged: cubit.setSearchQuery,
                  onClearFilters: () {
                    cubit.setCategoryFilter(null);
                    cubit.setSearchQuery('');
                  },
                  showArchivedToggle: true,
                  onArchivedToggleChanged: cubit.setIncludeArchived,
                ),
                const SizedBox(height: AvahiSpacing.sm),
                if (data.isDocumentsLoading)
                  const Expanded(child: LoadingIndicator())
                else if (data.filteredDocuments.isEmpty)
                  Expanded(
                    child: EmptyState(
                      title: data.hasActiveFilters
                          ? 'لا نتائج مطابقة للفلاتر'
                          : 'لا توجد مستندات بعد',
                      message: data.hasActiveFilters
                          ? 'جرّب تعديل معايير التصفية.'
                          : 'ارفع أول مستند عبر زر "رفع مستند" أعلاه.',
                      icon: Icons.folder_open_outlined,
                    ),
                  )
                else
                  Expanded(
                    child: _viewMode == _ViewMode.category
                        ? DocumentCategories(
                            data: data,
                            onDocumentTap: cubit.selectDocument,
                          )
                        : ListView.separated(
                            itemCount: data.filteredDocuments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AvahiSpacing.sm),
                            itemBuilder: (BuildContext context, int index) {
                              final Document document =
                                  data.filteredDocuments[index];
                              return DocumentCard(
                                document: document,
                                projectLabel: document.projectId == null
                                    ? null
                                    : data.projectsById[document.projectId]
                                        ?.name,
                                onTap: () => cubit.selectDocument(document),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        ),
        DocumentViewerPanel(onClose: () => cubit.selectDocument(null)),
      ],
    );
  }
}

/// حوار رفع مستند جديد — يظهر بعد اختيار الملف فعلياً عبر
/// `DocumentsCubit.pickDocumentFile` (`documents_manager.dart._openUploadDialog`)،
/// يطلب فقط البيانات الوصفية المتبقية (العنوان، التصنيف، المشروع
/// المرتبط اختيارياً، وصف اختياري) قبل استدعاء
/// `DocumentsCubit.uploadPickedFile` الفعلي.
class _UploadDialog extends StatefulWidget {
  const _UploadDialog({
    required this.cubit,
    required this.data,
    required this.file,
  });

  final DocumentsCubit cubit;
  final DocumentsData data;
  final PickedFile file;

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _category;
  String? _projectId;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final int dotIndex = widget.file.fileName.lastIndexOf('.');
    _titleController = TextEditingController(
      text: dotIndex == -1
          ? widget.file.fileName
          : widget.file.fileName.substring(0, dotIndex),
    );
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);
    final Document? uploaded = await widget.cubit.uploadPickedFile(
      file: widget.file,
      projectId: _projectId,
      category: _category,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isUploading = false);

    if (uploaded != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر رفع المستند، حاول مجدداً.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفع مستند جديد'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AvahiTextField(label: 'اسم الملف', controller: _titleController),
            const SizedBox(height: AvahiSpacing.sm),
            AvahiDropdown<String?>(
              label: 'التصنيف',
              value: _category,
              items: <AvahiDropdownItem<String?>>[
                for (final String category in kDocumentCategories)
                  AvahiDropdownItem<String?>(value: category, label: category),
              ],
              onChanged: (String? value) => setState(() => _category = value),
            ),
            const SizedBox(height: AvahiSpacing.sm),
            AvahiDropdown<String?>(
              label: 'المشروع (اختياري — فارغ = مستند عام على مستوى الشركة)',
              value: _projectId,
              items: <AvahiDropdownItem<String?>>[
                const AvahiDropdownItem<String?>(
                  value: null,
                  label: 'مستند عام على مستوى الشركة',
                ),
                for (final project in widget.data.myProjects)
                  AvahiDropdownItem<String?>(
                    value: project.id,
                    label: project.name,
                  ),
              ],
              onChanged: (String? value) => setState(() => _projectId = value),
            ),
            const SizedBox(height: AvahiSpacing.sm),
            AvahiTextField(
              label: 'وصف (اختياري)',
              controller: _descriptionController,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        AvahiButton(
          label: 'إلغاء',
          variant: AvahiButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AvahiButton(
          label: 'رفع',
          isLoading: _isUploading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
