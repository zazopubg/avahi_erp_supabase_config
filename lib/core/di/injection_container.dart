import 'package:get_it/get_it.dart';

import 'core_module.dart';
import 'data_module.dart';
import 'domain_module.dart';
import 'features_module.dart';

/// حاوية حقن التبعيات الموحّدة لكامل التطبيق (`get_it`).
///
/// ⚠️ قرار تصميم: `injectable` مُدرَج ضمن `pubspec.yaml` (Prompt 00)
/// للاستخدام المستقبلي المحتمل، لكن هذه الخطوة تعتمد تسجيلاً يدوياً
/// منظّماً (Manual Registration) عبر وحدات صريحة (`core_module.dart`،
/// `data_module.dart`، `domain_module.dart`، `features_module.dart`)
/// بدل التوليد التلقائي (`@injectable`/`build_runner`): يبقي هذا كل
/// تبعية مرئية وقابلة للتتبع مباشرة من نص الكود دون انتظار خطوة توليد
/// إضافية، وهو أهم فعلياً في هذه المرحلة المبكرة (`flutter run -d
/// chrome` يجب أن يعمل فوراً بعد هذه الخطوة). يمكن الانتقال لاحقاً إلى
/// `@injectable` إن كبر عدد التسجيلات كثيراً دون أي تغيير في طريقة
/// استهلاك `sl<T>()` من بقية الطبقات.
final GetIt sl = GetIt.instance;

/// يجمع كل وحدات الحقن الأربع بترتيب الاعتماد الصحيح: `core` (لا يعتمد
/// على شيء) → `data` (يعتمد على بعض خدمات `core`، مثل [SessionService])
/// → `domain` (يعتمد على مستودعات `data`) → `features` (فارغة الآن،
/// ستعتمد على `domain`/`data` معاً لاحقاً).
///
/// يُستدعى مرة واحدة فقط من `lib/bootstrap.dart` أثناء إقلاع التطبيق،
/// **بعد** نجاح `SupabaseClientProvider.initialize()` مباشرة (بعض
/// التسجيلات هنا كسولة `LazySingleton` ولن تُنشئ فعلياً أي شيء إلا عند
/// أول استخدام، لكن الترتيب الصحيح بين الوحدات يبقى ضرورياً لصحة رسم
/// بياني الاعتماد نفسه).
void configureDependencies() {
  registerCoreModule(sl);
  registerDataModule(sl);
  registerDomainModule(sl);
  registerFeaturesModule(sl);
}
