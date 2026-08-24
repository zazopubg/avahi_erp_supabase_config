import 'package:drift/drift.dart';

/// جدول محلي (Drift) لطابور رفع الصور (Photo Upload Queue) — **ليس**
/// مرآة كاملة لجدول `public.photos` (انظر
/// `backend/supabase/migrations/009_create_photos.sql`)، بل بالتحديد
/// طابور الصور الملتقطة محلياً (Prompt 18/كاميرا الحقل) بانتظار رفعها
/// إلى Supabase Storage (Bucket `photos`) ثم إدراج صفها في جدول
/// `photos` السحابي.
///
/// دورة حياة الصف:
/// 1) تُلتقط الصورة → صف جديد بـ [syncState] = `pending` و
///    [localFileBytes] يحمل البايتات المضغوطة (`ImageCompressor`).
/// 2) عند توفر الاتصال، يرفع [PhotoUploadProcessor]
///    (`data/sync/outbox/photo_upload_processor.dart`، Prompt 18) هذه
///    البايتات ويملأ [remoteStoragePath]/[thumbnailStoragePath] ثم
///    يُحدِّث [syncState] إلى `synced`.
/// 3) [id] هو نفسه معرّف صف `photos.id` السحابي المستقبلي (مولَّد
///    محلياً مسبقاً عبر `IdGenerator`)، فلا حاجة لإعادة ربط لاحقاً —
///    ويُرسَل فعلياً ضمن الإدراج السحابي (`SitePhotoDto.toInsertJson`)
///    بدءاً من Prompt 18 (انظر توثيق القرار هناك)، بعد أن كان الحقل
///    مُعرَّفاً هنا منذ Prompt 08 دون استخدام فعلي مطابق حتى الآن.
///
/// ⚠️ تصحيح تصميم مهم عند البناء الفعلي في Prompt 18: الحقل الأصلي
/// [localFilePath] (Prompt 08) افترض ضمناً وجود مسار ملف فعلي على
/// نظام تشغيل الجهاز. المشروع يستهدف المتصفح (Chrome) حصراً في هذه
/// المرحلة (انظر `core/platform/capability_service.dart` —
/// `AppCapability.fileSystemAccess: false`)، حيث لا يوجد أي وصول
/// مباشر لنظام ملفات حقيقي داخل صندوق حماية المتصفح. القيمة العملية
/// الوحيدة المتاحة فعلياً هي بايتات الصورة نفسها (`Uint8List`)، وأخزّنها
/// كعمود [BlobColumn] ضمن نفس قاعدة SQLite المحلية (`sqlite3` عبر
/// `drift_flutter`، وهي مبنية أصلاً فوق OPFS/IndexedDB على الويب —
/// تخزين بايتات صورة بضعة ميغابايتات داخلها أمر معتاد ومدعوم بالكامل،
/// خلافاً لنظام ملفات OS خام). يبقى [localFilePath] مُعرَّفاً هنا (بلا
/// حذف أي بنية سابقة، التزاماً بقواعد الترقيع) لكن بدلالة مُعاد
/// تفسيرها بوضوح: اسم الملف المعروض فقط (لاستخراج الامتداد/نوع
/// المحتوى وعرضه في واجهة المستخدم)، وليس مساراً فعلياً على القرص.
@DataClassName('PhotoQueueRow')
class PhotoQueueTable extends Table {
  @override
  String get tableName => 'local_photo_queue';

  TextColumn get id => text()();
  TextColumn get clientMutationId => text().unique()();

  TextColumn get companyId => text()();
  TextColumn get projectId => text().nullable()();

  /// قيمة [RelatedEntityType.dbValue] النصية.
  TextColumn get relatedEntityType => text()();
  TextColumn get relatedEntityId => text()();

  /// اسم الملف المعروض فقط (مثال: `IMG_20260816.jpg`) — **ليس** مساراً
  /// فعلياً على القرص (انظر توثيق القرار أعلى الصنف). يُستخدم فقط
  /// لاستخراج الامتداد/تخمين نوع المحتوى وعرض اسم مألوف للمستخدم.
  TextColumn get localFilePath => text()();

  /// نوع محتوى الصورة الفعلي (`image/jpeg` افتراضياً بعد ضغط
  /// `ImageCompressor` دائماً لصيغة JPEG موحّدة) — يُمرَّر حرفياً إلى
  /// `PhotoStorageService.uploadPhoto(contentType: ...)` عند الرفع.
  TextColumn get mimeType =>
      text().withDefault(const Constant('image/jpeg'))();

  /// بايتات الصورة الأصل (بعد الضغط الفوري عبر `ImageCompressor` وقت
  /// الالتقاط) — المصدر الوحيد الفعلي للرفع (انظر توثيق القرار أعلى
  /// الصنف حول غياب نظام ملفات حقيقي على الويب).
  BlobColumn get localFileBytes => blob()();

  /// بايتات نسخة مصغّرة (Thumbnail) اختيارية، مضغوطة بأبعاد أصغر —
  /// تُستخدم لعرض فوري في `photo_grid.dart`/`photo_thumbnail.dart` قبل
  /// اكتمال الرفع (بدل الانتظار لرابط موقّع سحابي غير موجود بعد).
  BlobColumn get localThumbnailBytes => blob().nullable()();

  /// يُملأ بعد نجاح الرفع بمسار الكائن داخل Bucket `photos`
  /// (`ApiConstants.bucketPhotos`).
  TextColumn get remoteStoragePath => text().nullable()();
  TextColumn get thumbnailStoragePath => text().nullable()();

  /// ⚠️ لا يوجد عمود وسوم (Tags) مخصص في مخطط `public.photos`
  /// (`009_create_photos.sql` — انظر أيضاً `domain/entities/site_photo.dart`).
  /// `photo_tag_selector.dart` (Prompt 18) يُدمج الوسوم المختارة داخل
  /// هذا الحقل نفسه بصيغة بادئة هاشتاغ ثابتة (`#وسم1 #وسم2 نص
  /// التعليق`)، يفكّكها `PhotosData.tagsOf`/`captionTextOf`
  /// (`presentation/state/photos_state.dart`) عند العرض — حل عملي لا
  /// يتطلب أي تعديل على مخطط قاعدة البيانات السحابية.
  TextColumn get caption => text().nullable()();
  IntColumn get fileSizeBytes => integer().nullable()();

  DateTimeColumn get takenAt => dateTime()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  TextColumn get uploadedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// يبدأ الصف دائماً بحالة `pending` (خلافاً لبقية الجداول التي
  /// تفترض `synced` افتراضياً)، لأن كل صف هنا بحكم تعريفه بانتظار
  /// رفع لم يتم بعد.
  TextColumn get syncState =>
      text().withDefault(const Constant('pending'))();

  IntColumn get uploadAttempts =>
      integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// 🆕 (Prompt 18) وقت آخر محاولة رفع فاشلة — كان غائباً منذ Prompt
  /// 08 رغم حاجة [RetryPolicy.isDueForRetry] (`data/sync/retry/`) له
  /// فعلياً؛ بدونه لا يمكن حساب التأخير التصاعدي (Exponential Backoff)
  /// بين محاولات إعادة رفع صورة فاشلة بنفس السياسة المعتمدة في
  /// `OutboxTable` تماماً. `null` حتى أول فشل فعلي.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
