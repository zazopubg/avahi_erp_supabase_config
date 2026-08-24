/// ملف تجميعي (Barrel File) لميزة `features/documents/` كاملة —
/// يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل
/// شاشات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/punch_list/punch_list_feature.dart`/`features/projects/projects_feature.dart`
/// تماماً.
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشتين يستهلكهما `app_router.dart`
/// مباشرة كنقطتَي `go_router` — [DocumentsListScreen] (`/documents`،
/// تُفوِّض داخلياً لـ [DocumentsManager] على سطح المكتب دون مسار منفصل
/// لها، بنفس منطق `PunchListScreen`/`PunchDashboard`) و
/// [DocumentViewerScreen] (`/documents/:id`، عبر [DocumentRouteArgs]
/// الممرَّرة كـ `extra:` — بنفس منطق `ProjectRouteArgs`/
/// `PunchItemDetailsRouteArgs`). [DocumentsManager]/[DocumentViewerPanel]/
/// [DocumentCategories] داخلية بالكامل (يستهلكها [DocumentsListScreen]
/// نفسها حسب `ShellMode`) لكنها مُصدَّرة أيضاً لتسهيل اختبارها بمعزل
/// لاحقاً في `test/` (Prompt 29).
library;

export 'presentation/screens/desktop/document_categories.dart';
export 'presentation/screens/desktop/document_viewer.dart';
export 'presentation/screens/desktop/documents_manager.dart';
export 'presentation/screens/mobile/documents_list.dart';
export 'presentation/screens/shared/document_route_args.dart';
export 'presentation/state/documents_cubit.dart';
export 'presentation/state/documents_state.dart';
export 'presentation/widgets/document_card.dart';
export 'presentation/widgets/document_filter_bar.dart';
export 'presentation/widgets/document_scope_selector.dart';
