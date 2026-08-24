import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/site_photo.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../state/upload_queue_state.dart';

/// مصغّرة صورة واحدة — تعرض إما صورة مرفوعة فعلياً ([SitePhoto]، عبر
/// رابط موقّع يُحلَّل كسولاً بنفس نمط `report_photo_attach.dart`
/// (Prompt 17))، أو عنصر طابور محلي لم يُرفَع بعد ([UploadQueueItem]،
/// عبر بايتات المصغّرة المحفوظة محلياً في `Uint8List.memory` — لا رابط
/// سحابياً موجوداً بعد لعرضه). الحالتان متبادلتان تماماً عبر منشئين
/// مسمَّيين منفصلين، تُستخدَم من `photo_grid.dart` التي تعرض القائمتين
/// معاً بصرياً.
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail.uploaded({
    required SitePhoto photo,
    required Future<String?> Function(String storagePath) resolveSignedUrl,
    super.key,
    this.onTap,
    this.selected = false,
  })  : _photo = photo,
        _resolveSignedUrl = resolveSignedUrl,
        _queueItem = null;

  const PhotoThumbnail.queued({
    required UploadQueueItem queueItem,
    super.key,
    this.onTap,
    this.selected = false,
  })  : _queueItem = queueItem,
        _photo = null,
        _resolveSignedUrl = null;

  final SitePhoto? _photo;
  final UploadQueueItem? _queueItem;
  final Future<String?> Function(String storagePath)? _resolveSignedUrl;

  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: AvahiRadius.radiusMd,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AvahiRadius.radiusMd,
          border: selected ? Border.all(color: colors.brand, width: 2) : null,
        ),
        child: ClipRRect(
          borderRadius: AvahiRadius.radiusMd,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _photo != null
                    ? _UploadedImage(photo: _photo, resolveSignedUrl: _resolveSignedUrl!)
                    : _QueuedImage(item: _queueItem!),
                if (_queueItem != null) _StatusBadge(item: _queueItem),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadedImage extends StatelessWidget {
  const _UploadedImage({required this.photo, required this.resolveSignedUrl});

  final SitePhoto photo;
  final Future<String?> Function(String storagePath) resolveSignedUrl;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final String path = photo.thumbnailPath ?? photo.storagePath;

    return FutureBuilder<String?>(
      future: resolveSignedUrl(path),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: colors.surfaceVariant,
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final String? url = snapshot.data;
        if (url == null) {
          return ColoredBox(
            color: colors.surfaceVariant,
            child: Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
          );
        }
        return Image.network(url, fit: BoxFit.cover);
      },
    );
  }
}

class _QueuedImage extends StatelessWidget {
  const _QueuedImage({required this.item});

  final UploadQueueItem item;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final List<int>? bytes = item.thumbnailBytes;
    if (bytes == null || bytes.isEmpty) {
      return ColoredBox(
        color: colors.surfaceVariant,
        child: Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
      );
    }
    return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover);
  }
}

/// شارة صغيرة أعلى المصغّرة توضّح حالة الرفع لعنصر طابور محلي —
/// "جارٍ الرفع"، أو تحذير أحمر عند الفشل.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final UploadQueueItem item;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    if (item.status == UploadItemStatus.failed) {
      return Positioned(
        top: 4,
        left: 4,
        child: _Badge(
          color: colors.danger,
          icon: Icons.error_outline,
        ),
      );
    }

    return Positioned(
      top: 4,
      left: 4,
      child: _Badge(
        color: colors.warning,
        icon: Icons.cloud_upload_outlined,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}
