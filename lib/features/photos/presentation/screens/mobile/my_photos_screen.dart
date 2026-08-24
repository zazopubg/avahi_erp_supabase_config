import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../data/storage/photo_storage_service.dart';
import '../../../../../domain/entities/site_photo.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/photos_cubit.dart';
import '../../state/photos_state.dart';
import '../../state/upload_queue_state.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/photo_viewer.dart';
import '../../widgets/upload_progress_indicator.dart';

/// شاشة "صوري" — واجهة الجوال الرئيسية لميزة `features/photos/`
/// (`RoutePaths.photos`، `/photos`)، تُقدَّم من `photos_screen.dart`
/// عندما `context.shellMode.isMobile`. تعرض افتراضياً صور المستخدم
/// الحالي فقط (`PhotosCubit.loadInitial(user, onlyMine: true)`)، مع
/// شريط حالة طابور الرفع أعلاها وزر عائم لالتقاط صورة جديدة.
class MyPhotosScreen extends StatelessWidget {
  const MyPhotosScreen({required this.photoStorageService, super.key});

  /// يُحقَن مباشرة (وليس عبر Cubit) لأن تحليل الروابط الموقّعة عملية
  /// عرض بحتة لا تستحق المرور بطبقة الحالة — بنفس نمط
  /// `report_photo_attach.dart` (Prompt 17).
  final PhotoStorageService photoStorageService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotosCubit, PhotosState>(
      builder: (BuildContext context, PhotosState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('صوري الميدانية')),
          floatingActionButton: state.maybeWhen(
            loaded: (PhotosData data) => FloatingActionButton(
              onPressed: data.isCapturing
                  ? null
                  : () => context.pushNamed(
                        RouteNames.photosCamera,
                        extra: context.read<PhotosCubit>(),
                      ),
              child: data.isCapturing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
            ),
            orElse: () => null,
          ),
          body: state.when(
            loading: () => const LoadingIndicator(label: 'جارٍ تحميل الصور...'),
            error: (failure) => ErrorView(
              title: 'تعذّر تحميل الصور',
              message: failure.message,
            ),
            loaded: (PhotosData data) => RefreshIndicator(
              onRefresh: () => context.read<PhotosCubit>().refresh(),
              child: Column(
                children: <Widget>[
                  UploadProgressIndicator(
                    queue: data.uploadQueue,
                    onRetryAllFailed: () {
                      for (final UploadQueueItem item in data.uploadQueue.items) {
                        if (item.status == UploadItemStatus.failed) {
                          context.read<PhotosCubit>().retryUpload(item.id);
                        }
                      }
                    },
                  ),
                  Expanded(
                    child: PhotoGrid(
                      photos: data.filteredPhotos,
                      queueItems: data.uploadQueue.items,
                      resolveSignedUrl: (String path) =>
                          photoStorageService.getSignedUrl(path).then(
                            (ResultOf<String> r) => r.getOrNull(),
                          ),
                      onPhotoTap: (SitePhoto photo) => _openViewer(context, data, photo),
                      emptyMessage:
                          'لم تلتقط أي صورة ميدانية بعد. اضغط زر الكاميرا للبدء.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openViewer(BuildContext context, PhotosData data, SitePhoto photo) async {
    final PhotosCubit cubit = context.read<PhotosCubit>();
    final ResultOf<String> signedUrl = await photoStorageService.getSignedUrl(
      photo.storagePath,
    );
    final String? url = signedUrl.getOrNull();
    if (url == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewer(
          photo: photo,
          imageUrl: url,
          uploaderName: photo.uploadedBy == data.currentUser.userId
              ? data.currentUser.fullName
              : 'مستخدم آخر',
          onDelete: () async {
            await cubit.deletePhoto(photo);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
