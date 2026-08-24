import '../../../../../domain/entities/document.dart';
import '../../state/documents_cubit.dart';

/// حزمة وسيطة (Args) تُمرَّر عبر `extra:` لمسار `/documents/:id`
/// (`document_viewer.dart`) — تحمل [Document] المختار مسبقاً **و**نسخة
/// [DocumentsCubit] الحيّة نفسها التي فتحت الشاشة (من
/// `documents_manager.dart` أو `documents_list.dart`)، بنفس نمط
/// `PunchItemDetailsRouteArgs`/`ProjectRouteArgs` تماماً — يضمن أن أي
/// إجراء (أرشفة، رفع إصدار جديد...) داخل `document_viewer.dart` ينعكس
/// فوراً على نفس القائمة خلفها عند العودة إليها.
///
/// ⚠️ بخلاف `ProjectRouteArgs` (معرّف فقط، يُعاد الجلب عند الحاجة)
/// وبنفس منطق `PunchItemDetailsRouteArgs.item` — [document] الكامل
/// يُمرَّر مباشرة هنا لأن [DocumentsCubit] لا يملك مفهوم "مستند مختار
/// حالياً بمعرّفه فقط" منفصلاً عن القائمة المحمَّلة أصلاً، وتجنّباً
/// لاستدعاء شبكة إضافي غير ضروري عند التنقّل من قائمة محمَّلة أصلاً.
/// الدخول المباشر (Deep Link) بلا `extra:` يعتمد بدلاً من ذلك
/// `DocumentsCubit.loadSingleDocument` — انظر توثيقها.
class DocumentRouteArgs {
  const DocumentRouteArgs({required this.document, required this.cubit});

  final Document document;
  final DocumentsCubit cubit;
}
