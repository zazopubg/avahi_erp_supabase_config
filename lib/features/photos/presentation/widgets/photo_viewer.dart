import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/site_photo.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../state/photos_state.dart';

/// عارض صورة مكبَّر بملء الشاشة — `InteractiveViewer` للتكبير/التصغير
/// السلس بإيماءتَي القرص (Pinch-to-zoom) والسحب، فوق طبقة بيانات
/// وصفية (Metadata) سفلية: التوقيت، الموقع الجغرافي (إن وُجد)،
/// والمصوِّر — تُفتح من `photo_grid.dart` (عبر `Navigator.push`، بنفس
/// نمط `camera_screen.dart`) عند الضغط على أي صورة مؤكدة (مرفوعة
/// فعلاً؛ عناصر الطابور المحلي لا تفتح عارضاً كاملاً بعد — انظر
/// `photo_thumbnail.dart`).
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({
    required this.photo,
    required this.imageUrl,
    required this.uploaderName,
    super.key,
    this.onDelete,
  });

  final SitePhoto photo;

  /// رابط موقّع مُحلَّل مسبقاً من الشاشة الأم (`PhotoStorageService.getSignedUrl`)
  /// — هذه الودجة عرض بحت، لا تحلّل روابط بنفسها.
  final String imageUrl;

  final String uploaderName;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final List<String> tags = PhotosData.tagsOf(photo);
    final String captionText = PhotosData.captionTextOf(photo);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AvahiSpacing.md),
            color: Colors.black.withValues(alpha: 0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (captionText.isNotEmpty) ...<Widget>[
                  Text(
                    captionText,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: AvahiSpacing.xs),
                ],
                if (tags.isNotEmpty) ...<Widget>[
                  Wrap(
                    spacing: AvahiSpacing.xxs,
                    children: tags
                        .map(
                          (String t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: AvahiSpacing.xs),
                ],
                _MetadataRow(icon: Icons.person_outline, label: uploaderName),
                _MetadataRow(
                  icon: Icons.schedule_outlined,
                  label: DateFormatter.dateTime(photo.takenAt),
                ),
                if (photo.latitude != null && photo.longitude != null)
                  _MetadataRow(
                    icon: Icons.location_on_outlined,
                    label:
                        '${photo.latitude!.toStringAsFixed(5)}, ${photo.longitude!.toStringAsFixed(5)}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف الصورة؟'),
        content: const Text('لا يمكن التراجع عن هذا الإجراء.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: AvahiSpacing.xxs),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
