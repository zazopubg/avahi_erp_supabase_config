import 'package:flutter/material.dart';

import '../../../../domain/entities/site_photo.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// شريط أفقي لصور مرفقة بتقرير — عرض مصغّرات (عبر رابط موقّع يُحلَّل
/// كسولاً لكل صورة عبر [resolveSignedUrl])، وزرّا إضافة (كاميرا/معرض).
/// ودجة عرض بحتة بالكامل: `report_form_screen.dart` يمرّر
/// [photos]/[isUploading] من [ReportFormData] ويربط ردود الأفعال
/// بدوال `ReportFormCubit.attachPhotoFromCamera`/`pickFromGallery`/
/// `removePhoto` مباشرة، بنفس نمط باقي ودجات هذه الميزة الحوارية.
class ReportPhotoAttach extends StatelessWidget {
  const ReportPhotoAttach({
    required this.photos,
    required this.isUploading,
    required this.onAddFromCamera,
    required this.onAddFromGallery,
    required this.onRemove,
    required this.resolveSignedUrl,
    super.key,
    this.enabled = true,
  });

  final List<SitePhoto> photos;
  final bool isUploading;
  final VoidCallback onAddFromCamera;
  final VoidCallback onAddFromGallery;
  final ValueChanged<String> onRemove;

  /// يحلّ `storagePath` إلى رابط موقّع (Signed URL) صالح للعرض —
  /// `report_form_screen.dart` يمرّر `PhotoStorageService.getSignedUrl`
  /// عبر حاوية حقن التبعيات مباشرة (`sl<PhotoStorageService>()`).
  final Future<String?> Function(String storagePath) resolveSignedUrl;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('الصور المرفقة', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.only(left: AvahiSpacing.xs),
                child: SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        const SizedBox(height: AvahiSpacing.xs),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 2,
            separatorBuilder: (_, __) => const SizedBox(width: AvahiSpacing.xs),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return _AddPhotoButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'كاميرا',
                  onPressed: enabled && !isUploading ? onAddFromCamera : null,
                );
              }
              if (index == 1) {
                return _AddPhotoButton(
                  icon: Icons.photo_library_outlined,
                  label: 'معرض',
                  onPressed: enabled && !isUploading ? onAddFromGallery : null,
                );
              }

              final SitePhoto photo = photos[index - 2];
              return _PhotoThumbnail(
                photo: photo,
                resolveSignedUrl: resolveSignedUrl,
                onRemove: enabled ? () => onRemove(photo.id) : null,
                colors: colors,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: AvahiRadius.radiusMd,
      child: Container(
        width: 84,
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: AvahiRadius.radiusMd,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: onPressed == null ? colors.outline : colors.primary),
            const SizedBox(height: AvahiSpacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onPressed == null ? colors.outline : colors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.resolveSignedUrl,
    required this.onRemove,
    required this.colors,
  });

  final SitePhoto photo;
  final Future<String?> Function(String storagePath) resolveSignedUrl;
  final VoidCallback? onRemove;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AvahiRadius.radiusMd,
      child: Stack(
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 96,
            child: FutureBuilder<String?>(
              future: resolveSignedUrl(photo.storagePath),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                final String? url = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (url == null) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
                  );
                }
                return Image.network(url, fit: BoxFit.cover);
              },
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colors.scrim.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
