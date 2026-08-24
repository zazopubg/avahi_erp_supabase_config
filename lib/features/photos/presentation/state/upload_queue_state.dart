import 'package:equatable/equatable.dart';

import '../../../../data/local/local_database.dart' show PhotoQueueRow;
import '../../../../domain/enums/related_entity_type.dart';

/// حالة رفع عنصر واحد ضمن طابور الصور المحلي — انعكاس مبسّط لعمود
/// `PhotoQueueTable.syncState` (`data/local/tables/photo_queue_table.dart`)
/// لا يفصح عن تفاصيل Drift للطبقة العلوية.
enum UploadItemStatus {
  /// بانتظار الرفع (لم تُحاوَل بعد، أو مستحقة لإعادة محاولة).
  pending,

  /// الرفع جارٍ الآن فعلياً (يُحدَّد محلياً في `PhotosCubit` أثناء
  /// معالجة العنصر — لا مقابل مباشر له في `PhotoQueueTable.syncState`
  /// نفسه، الذي لا يميّز "جارٍ" عن "معلّق").
  uploading,

  /// فشلت آخر محاولة (`PhotoQueueTable.syncState == 'failed'`) —
  /// سيُعاد المحاولة تلقائياً بحسب `RetryPolicy`، أو يدوياً عبر
  /// `upload_progress_indicator.dart`.
  failed;

  static UploadItemStatus fromRow(String syncState) {
    switch (syncState) {
      case 'failed':
        return UploadItemStatus.failed;
      default:
        return UploadItemStatus.pending;
    }
  }
}

/// عنصر واحد في طابور الرفع — عرض مبسّط لصف [PhotoQueueRow] Drift
/// خام، يخفي تفاصيل التخزين المحلي (البايتات نفسها) عن واجهة المستخدم
/// (لا حاجة لها إلا عند الرفع الفعلي داخل `PhotoUploadProcessor`).
class UploadQueueItem extends Equatable {
  const UploadQueueItem({
    required this.id,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.status,
    required this.uploadAttempts,
    required this.takenAt,
    this.caption,
    this.lastError,
    this.thumbnailBytes,
  });

  factory UploadQueueItem.fromRow(
    PhotoQueueRow row, {
    UploadItemStatus? overrideStatus,
  }) {
    return UploadQueueItem(
      id: row.id,
      relatedEntityType: RelatedEntityType.fromDbValue(row.relatedEntityType),
      relatedEntityId: row.relatedEntityId,
      status: overrideStatus ?? UploadItemStatus.fromRow(row.syncState),
      uploadAttempts: row.uploadAttempts,
      takenAt: row.takenAt,
      caption: row.caption,
      lastError: row.lastError,
      thumbnailBytes: row.localThumbnailBytes,
    );
  }

  final String id;
  final RelatedEntityType relatedEntityType;
  final String relatedEntityId;
  final UploadItemStatus status;
  final int uploadAttempts;
  final DateTime takenAt;
  final String? caption;
  final String? lastError;

  /// بايتات المصغّرة المحلية (إن وُجدت) لعرض معاينة فورية في
  /// `upload_progress_indicator.dart`/`photo_thumbnail.dart` قبل
  /// اكتمال الرفع، بلا حاجة لانتظار رابط سحابي موقّع غير موجود بعد.
  final List<int>? thumbnailBytes;

  UploadQueueItem copyWith({UploadItemStatus? status}) {
    return UploadQueueItem(
      id: id,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      status: status ?? this.status,
      uploadAttempts: uploadAttempts,
      takenAt: takenAt,
      caption: caption,
      lastError: lastError,
      thumbnailBytes: thumbnailBytes,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        relatedEntityType,
        relatedEntityId,
        status,
        uploadAttempts,
        takenAt,
        caption,
        lastError,
      ];
}

/// حالة كامل طابور رفع الصور — عنصر فرعي ضمن [PhotosData]
/// (`photos_state.dart`)، يُدار بالتوازي مع قائمة الصور المُحمَّلة
/// فعلياً من السحابة (بنفس التوصيف الوارد في مهمة Prompt 18: "يدير
/// PhotosState... وUploadQueueState... بالتوازي"). ملف منفصل تماماً
/// (كما طُلب صراحة) رغم كونه يُحمَل ضمن نفس بث `Cubit<PhotosState>`
/// الواحد — لا يوجد `Cubit<UploadQueueState>` مستقل، إذ لا داعٍ لبث
/// حالة إضافي منفصل عن `PhotosCubit` نفسه.
class UploadQueueState extends Equatable {
  const UploadQueueState({
    this.items = const <UploadQueueItem>[],
  });

  final List<UploadQueueItem> items;

  int get pendingCount =>
      items.where((UploadQueueItem i) => i.status != UploadItemStatus.uploading).length;

  int get uploadingCount =>
      items.where((UploadQueueItem i) => i.status == UploadItemStatus.uploading).length;

  int get failedCount =>
      items.where((UploadQueueItem i) => i.status == UploadItemStatus.failed).length;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  UploadQueueState copyWith({List<UploadQueueItem>? items}) {
    return UploadQueueState(items: items ?? this.items);
  }

  /// يُحدِّث حالة عنصر واحد فقط ضمن القائمة (مثال: `pending` →
  /// `uploading` لحظة بدء `PhotosCubit._processQueueItem` فعلياً).
  UploadQueueState withItemStatus(String id, UploadItemStatus status) {
    return copyWith(
      items: items
          .map(
            (UploadQueueItem item) =>
                item.id == id ? item.copyWith(status: status) : item,
          )
          .toList(growable: false),
    );
  }

  static const UploadQueueState empty = UploadQueueState();

  @override
  List<Object?> get props => <Object?>[items];
}
