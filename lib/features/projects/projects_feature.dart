/// ملف تصدير تجميعي لميزة `features/projects/` (Prompt 20) — إدارة
/// المشاريع، المراحل الرئيسية، وفريق العمل. بنفس نمط
/// `punch_list_feature.dart`/`photos_feature.dart`: يجمع كل الأجزاء
/// العامة القابلة للاستخدام من خارج الميزة (نقطة الدخول، الـ Cubit/
/// State، الحزم الوسيطة للتنقّل) في استيراد واحد مختصر.
library;

export 'presentation/screens/desktop/project_details.dart';
export 'presentation/screens/desktop/project_members.dart';
export 'presentation/screens/desktop/project_milestones.dart';
export 'presentation/screens/desktop/project_settings.dart';
export 'presentation/screens/desktop/projects_list.dart';
export 'presentation/screens/mobile/my_projects_screen.dart';
export 'presentation/screens/mobile/project_overview.dart';
export 'presentation/screens/shared/project_route_args.dart';
export 'presentation/state/projects_cubit.dart';
export 'presentation/state/projects_state.dart';
export 'presentation/widgets/member_role_selector.dart';
export 'presentation/widgets/project_card.dart';
export 'presentation/widgets/project_progress_bar.dart';
export 'presentation/widgets/project_status_badge.dart';
