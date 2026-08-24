/// ملف تجميعي (Barrel File) لميزة `features/__feature_name__/` كاملة —
/// يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل
/// شاشات وحالة هذه الميزة عبر سطر واحد:
/// `import 'package:avahi/features/__feature_name__/__feature_name___feature.dart';`
///
/// بنفس نمط `features/equipment/equipment_feature.dart` و
/// `features/documents/documents_feature.dart` تماماً.
///
/// TODO: بعد بناء الميزة فعلياً، وثّق هنا (بتعليق مشابه لهذا) أي قرار
/// نطاق خاص بميزتك — مثال: هل تُستخدَم شاشة دخول واحدة بمنطق تكييف
/// داخلي (`ShellMode`)، أم تفرّع كامل `screens/mobile/` +
/// `screens/desktop/`؟ انظر
/// docs/architecture/05_responsive_web.md#أنماط-تفرّع-الشاشات-داخل-الميزات.
library;

export 'presentation/screens/mobile/__feature_name___mobile_home.dart';
// TODO: أزل هذا التصدير إن اخترت شاشة واحدة بمنطق تكييف داخلي بدل تفرّع كامل.
export 'presentation/screens/desktop/__feature_name___desktop_home.dart';
export 'presentation/state/__feature_name___cubit.dart';
export 'presentation/state/__feature_name___state.dart';
