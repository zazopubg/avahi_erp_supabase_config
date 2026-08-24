// ============================================================
// tools/generators/feature_template/di_snippet.dart.tpl
// ليس ملف Dart قابلاً للتنفيذ مباشرة — مقتطف مرجعي (Snippet) يُلصَق
// يدوياً داخل lib/core/di/features_module.dart بعد توليد الميزة،
// بنفس نمط `_registerEquipmentFeature` الموجود فعلياً في ذلك الملف.
//
// خطوات الدمج:
// 1) الصق دالة `_register__FeatureName__Feature` أدناه (بعد استبدال
//    __feature_name__/__FeatureName__ بالاسم الفعلي) في نهاية
//    features_module.dart.
// 2) أضف سطر استدعائها `_register__FeatureName__Feature(sl);` ضمن
//    الدالة الرئيسية التي تستدعي بقية `_register*Feature` الحالية.
// 3) استورد `__FeatureName__Cubit` وكل UseCase الفعلية التي تحتاجها
//    أعلى features_module.dart.
// ============================================================

/// 🆕 `__FeatureName__Cubit` يقود كل شاشات ميزة `__feature_name__/`
/// معاً عبر [__FeatureName__Data] واحدة مجمّعة — بنفس منطق
/// `_registerEquipmentFeature`/`_registerDocumentsFeature` تماماً.
///
/// يُستهلَك من الشاشة عبر:
/// `BlocProvider<__FeatureName__Cubit>(create: (_) => sl<__FeatureName__Cubit>()..loadInitial(user))`
void _register__FeatureName__Feature(GetIt sl) {
  sl.registerFactory<__FeatureName__Cubit>(
    () => __FeatureName__Cubit(
      // TODO: مرّر كل حالات الاستخدام (usecases) الفعلية هنا،
      // كل واحدة عبر sl<UsecaseType>() — يجب أن تكون كل حالات
      // الاستخدام مسجَّلة مسبقاً في domain_module.dart/data_module.dart.
    ),
  );
}
