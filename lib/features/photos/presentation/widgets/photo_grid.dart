import 'package:flutter/material.dart';

import '../../../../domain/entities/site_photo.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import '../state/upload_queue_state.dart';
import 'photo_thumbnail.dart';

/// شبكة صور موحّدة — تعرض **معاً** صور [PhotosData.filteredPhotos]
/// المرفوعة فعلياً وعناصر [UploadQueueState.items] التي لا تزال بانتظار
/// الرفع (بشارة تمييز واضحة عبر `PhotoThumbnail.queued`)، تماشياً مع
/// إدارة الحالتين "بالتوازي" في `PhotosCubit`. تُستخدم من
/// `my_photos_screen.dart` (الجوال) و`photo_gallery.dart` (سطح المكتب)
/// معاً — عدد الأعمدة [crossAxisCount] هو الفرق الوحيد المتوقَّع بينهما.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    required this.photos,
    required this.queueItems,
    required this.resolveSignedUrl,
    required this.onPhotoTap,
    super.key,
    this.onQueueItemTap,
    this.selectedPhotoId,
    this.crossAxisCount = 3,
    this.emptyMessage = 'لا توجد صور بعد. التقط أول صورة ميدانية بزر الإضافة.',
  });

  final List<SitePhoto> photos;
  final List<UploadQueueItem> queueItems;
  final Future<String?> Function(String storagePath) resolveSignedUrl;
  final ValueChanged<SitePhoto> onPhotoTap;
  final ValueChanged<UploadQueueItem>? onQueueItemTap;
  final String? selectedPhotoId;
  final int crossAxisCount;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && queueItems.isEmpty) {
      return EmptyState(
        title: 'لا توجد صور',
        message: emptyMessage,
        icon: Icons.photo_camera_back_outlined,
      );
    }

    final int totalCount = queueItems.length + photos.length;

    return GridView.builder(
      padding: const EdgeInsets.all(AvahiSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AvahiSpacing.sm,
        mainAxisSpacing: AvahiSpacing.sm,
      ),
      itemCount: totalCount,
      itemBuilder: (BuildContext context, int index) {
        // عناصر الطابور المحلي أولاً (الأحدث زمنياً غالباً، وتحتاج
        // انتباه المستخدم أكثر لحالتها) ثم الصور المؤكدة السحابية.
        if (index < queueItems.length) {
          final UploadQueueItem item = queueItems[index];
          return PhotoThumbnail.queued(
            queueItem: item,
            onTap: onQueueItemTap == null ? null : () => onQueueItemTap!(item),
          );
        }

        final SitePhoto photo = photos[index - queueItems.length];
        return PhotoThumbnail.uploaded(
          photo: photo,
          resolveSignedUrl: resolveSignedUrl,
          selected: photo.id == selectedPhotoId,
          onTap: () => onPhotoTap(photo),
        );
      },
    );
  }
}
