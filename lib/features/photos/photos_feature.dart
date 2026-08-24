/// ملف تجميعي (Barrel File) لميزة `features/photos/` كاملة — يسمح لـ
/// `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل شاشات وحالة
/// هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/field_reports/field_reports_feature.dart` تماماً.
///
/// ⚠️ ملاحظة نطاق (بخلاف `field_reports_feature.dart` الذي يصدّر شاشة
/// دخول واحدة فقط): هذه الميزة تصدّر **ثلاث** شاشات يستهلكها
/// `app_router.dart` مباشرة كنقاط `go_router` منفصلة —
/// [PhotosScreen] (`/photos`)، [CameraScreen] (`/photos/camera`)،
/// و[PhotoAttachScreen] (`/photos/attach`) — لأن تدفّق الالتقاط هنا
/// يحتاج فعلياً مسارات قابلة للربط العميق (Deep-linkable) بدل
/// `Navigator.push` داخلي بحت كما في `report_photo_attach.dart`
/// (`features/field_reports/`)؛ انظر توثيق القرار الكامل في
/// `RoutePaths.photosCamera`/`photosAttach`. [MyPhotosScreen]/
/// [PhotoGallery]/[PhotoDetailsPanel] داخلية بالكامل (يستهلكها
/// [PhotosScreen] نفسها حسب `ShellMode`) لكنها مُصدَّرة أيضاً لتسهيل
/// اختبارها بمعزل لاحقاً في `test/` (Prompt 29).
library;

export 'presentation/screens/desktop/photo_details_panel.dart';
export 'presentation/screens/desktop/photo_gallery.dart';
export 'presentation/screens/mobile/camera_screen.dart';
export 'presentation/screens/mobile/my_photos_screen.dart';
export 'presentation/screens/mobile/photo_attach_screen.dart';
export 'presentation/screens/photos_screen.dart';
export 'presentation/state/photos_cubit.dart';
export 'presentation/state/photos_state.dart';
export 'presentation/state/upload_queue_state.dart';
