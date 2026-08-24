import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/document.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/documents_cubit.dart';
import '../../state/documents_state.dart';
import '../../widgets/document_card.dart';
import '../../widgets/document_filter_bar.dart';
import '../desktop/documents_manager.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.documents` (`/documents`) —
/// بنفس نمط `PunchListScreen` تماماً (انظر توثيق قرار التسمية الكامل
/// هناك): توفّر [DocumentsCubit] محلياً عبر
/// `sl<DocumentsCubit>()..loadInitial(user)` ثم تفرّع العرض حسب
/// [ShellMode] فقط — سطح المكتب/الجهاز اللوحي الواسع يُفوَّض بالكامل
/// إلى [DocumentsManager] (`screens/desktop/documents_manager.dart`)،
/// بينما يبقى هذا الملف نفسه (`mobile/documents_list.dart`) يجمع
/// المسؤوليتين معاً: نقطة الدخول الموحَّدة **و** واجهة الهاتف نفسها.
///
/// ⚠️ قرار تصميم جوهري (View-Only): بخلاف `documents_manager.dart`
/// (رفع/أرشفة/إصدارات كاملة)، واجهة الهاتف هنا **عرض فقط** — بلا أي
/// زر رفع أو أرشفة إطلاقاً بصرف النظر عن صلاحيات المستخدم الفعلية
/// (حتى لو ملك [Permission.documentsUpload])، لأن اختيار الملفات على
/// الهاتف عبر متصفح الويب أقل موثوقية وأبطأ بكثير من سطح المكتب لهذا
/// النوع تحديداً من الملفات (مخططات هندسية كبيرة، عقود...)، ولأن
/// معظم اتصال العمل الميداني الفعلي بهذه المستندات هو الاطّلاع عليها
/// لا رفعها أصلاً. لمس أي مستند يفتح رابطه الموقّع مباشرة في تبويب
/// متصفح جديد (`url_launcher`) بدل أي شاشة معاينة/إدارة مخصّصة —
/// لا يوجد ملف `document_viewer.dart` مكافئ تحت `mobile/` أصلاً، فقط
/// نظيره الوحيد تحت `desktop/`.
class DocumentsListScreen extends StatelessWidget {
  const DocumentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<DocumentsCubit>(
              create: (_) => sl<DocumentsCubit>()..loadInitial(user),
              child: const _DocumentsDispatcher(),
            );
          },
        );
      },
    );
  }
}

class _DocumentsDispatcher extends StatelessWidget {
  const _DocumentsDispatcher();

  @override
  Widget build(BuildContext context) {
    if (context.shellMode.isDesktop) return const DocumentsManager();
    return const _DocumentsListMobileBody();
  }
}

class _DocumentsListMobileBody extends StatelessWidget {
  const _DocumentsListMobileBody();

  Future<void> _openDocument(BuildContext context, Document document) async {
    final String? url = await context.read<DocumentsCubit>().getPreviewUrl(
          document,
        );
    if (url == null || !context.mounted) return;
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (BuildContext context, DocumentsState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('المستندات')),
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
                  authenticated: (AppUser user, _) =>
                      context.read<DocumentsCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (DocumentsData data) => RefreshIndicator(
              onRefresh: () => context.read<DocumentsCubit>().refresh(),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AvahiSpacing.md,
                      AvahiSpacing.sm,
                      AvahiSpacing.md,
                      0,
                    ),
                    child: DocumentFilterBar(
                      data: data,
                      onCategoryChanged: (category) => context
                          .read<DocumentsCubit>()
                          .setCategoryFilter(category),
                      onSearchChanged: (query) =>
                          context.read<DocumentsCubit>().setSearchQuery(query),
                      onClearFilters: () {
                        context.read<DocumentsCubit>().setCategoryFilter(null);
                        context.read<DocumentsCubit>().setSearchQuery('');
                      },
                    ),
                  ),
                  Expanded(
                    child: data.filteredDocuments.isEmpty
                        ? EmptyState(
                            title: data.hasActiveFilters
                                ? 'لا نتائج مطابقة للفلاتر'
                                : 'لا توجد مستندات متاحة بعد',
                            message: data.hasActiveFilters
                                ? 'جرّب تعديل معايير التصفية.'
                                : 'ستظهر هنا المستندات التي يشاركها فريقك.',
                            icon: Icons.folder_open_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AvahiSpacing.md),
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
                                onTap: () => _openDocument(context, document),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
