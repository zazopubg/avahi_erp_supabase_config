import 'package:flutter/material.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/storage/photo_storage_service.dart';
import '../../../../../domain/entities/site_photo.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../state/photos_state.dart';
import '../../widgets/photo_viewer.dart';

/// لوحة تفاصيل جانبية لصورة مختارة — سطح المكتب فقط
/// (`photo_gallery.dart`)، نظيرة `TaskDetailsPanel`/`report_details`
/// المكافئتين في ميزتَي `tasks`/`field_reports`. تعرض معاينة كاملة،
/// الوسوم، التعليق، الموقع الجغرافي (إن وُجد)، وبيانات الرفع — مع زرَي
/// "تكبير" (يفتح `photo_viewer.dart` بملء الشاشة) و"حذف".
class PhotoDetailsPanel extends StatelessWidget {
  const PhotoDetailsPanel({
    required this.photo,
    required this.photoStorageService,
    required this.onClose,
    required this.onDelete,
    super.key,
  });

  final SitePhoto photo;
  final PhotoStorageService photoStorageService;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final List<String> tags = PhotosData.tagsOf(photo);
    final String captionText = PhotosData.captionTextOf(photo);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AvahiSpacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('تفاصيل الصورة', style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
            child: ClipRRect(
              borderRadius: AvahiRadius.radiusMd,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: FutureBuilder<ResultOf<String>>(
                  future: photoStorageService.getSignedUrl(
                    photo.thumbnailPath ?? photo.storagePath,
                  ),
                  builder: (BuildContext context, AsyncSnapshot<ResultOf<String>> snapshot) {
                    final String? url = snapshot.data?.getOrNull();
                    if (url == null) {
                      return ColoredBox(
                        color: colors.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    return GestureDetector(
                      onTap: () => _openFullScreen(context, url),
                      child: Image.network(url, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AvahiSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (tags.isNotEmpty) ...<Widget>[
                    Wrap(
                      spacing: AvahiSpacing.xxs,
                      runSpacing: AvahiSpacing.xxs,
                      children: tags
                          .map(
                            (String t) => Chip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AvahiSpacing.sm),
                  ],
                  if (captionText.isNotEmpty) ...<Widget>[
                    Text(captionText, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AvahiSpacing.md),
                  ],
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'مرتبطة بـ',
                    value: photo.relatedEntityType.displayNameAr,
                  ),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'وقت الالتقاط',
                    value: DateFormatter.dateTime(photo.takenAt),
                  ),
                  if (photo.latitude != null && photo.longitude != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'الموقع',
                      value:
                          '${photo.latitude!.toStringAsFixed(5)}, ${photo.longitude!.toStringAsFixed(5)}',
                    ),
                  if (photo.fileSizeBytes != null)
                    _InfoRow(
                      icon: Icons.sd_storage_outlined,
                      label: 'الحجم',
                      value: '${(photo.fileSizeBytes! / 1024).toStringAsFixed(0)} كيلوبايت',
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: AvahiButton(
              label: 'حذف الصورة',
              icon: Icons.delete_outline,
              variant: AvahiButtonVariant.danger,
              isFullWidth: true,
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullScreen(BuildContext context, String url) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewer(
          photo: photo,
          imageUrl: url,
          uploaderName: photo.uploadedBy ?? '—',
        ),
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
    if (confirmed == true) onDelete();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.only(bottom: AvahiSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: AvahiSpacing.xs),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
