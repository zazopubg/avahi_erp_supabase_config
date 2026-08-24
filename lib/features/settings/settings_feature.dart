/// ميزة `features/settings/` (Prompt 27) — نقطة تصدير موحّدة، بنفس
/// نمط `notifications_feature.dart`/`users_feature.dart`: يستورد
/// `app_router.dart` من هذا الملف الواحد بدل الإشارة لمسارات فرعية
/// متفرقة داخل `presentation/`.
library;

export 'presentation/screens/about_screen.dart';
export 'presentation/screens/display_settings.dart';
export 'presentation/screens/glove_mode_settings.dart';
export 'presentation/screens/language_settings.dart';
export 'presentation/screens/notification_settings.dart';
export 'presentation/screens/profile_screen.dart';
export 'presentation/screens/settings_screen.dart';
export 'presentation/screens/sync_settings.dart';
export 'presentation/state/settings_cubit.dart';
export 'presentation/state/settings_state.dart';
