import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../data/storage/photo_storage_service.dart';
import '../../../../../domain/entities/site_photo.dart';
import '../../../../../domain/enums/related_entity_type.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/photos_cubit.dart';
import '../../state/photos_state.dart';
import '../../state/upload_queue_state.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/upload_progress_indicator.dart';
import 'photo_details_panel.dart';

/// واجهة سطح المكتب لميزة `features/photos/` — نفس نمط تخطيط لوحين
/// (List/Grid + Details) المعتمد أصلاً في
/// `features/tasks/presentation/screens/desktop/tasks_list_screen.dart`
/// (Prompt 16): شبكة صور المشروع كاملة (وليس صور المستخدم الحالي فقط
/// كـ`my_photos_screen.dart`) مع تبويبات فلترة حسب نوع الكيان على
/// اليمين، ولوحة تفاصيل جانبية ([PhotoDetailsPanel]) تظهر عند اختيار
/// صورة، تماماً كنافذة `TaskDetailsPanel` المكافئة.
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({required this.photoStorageService, super.key});

  final PhotoStorageService photoStorageService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotosCubit, PhotosState>(
      builder: (BuildContext context, PhotosState state) {
        return state.when(
          loading: () => const LoadingIndicator(label: 'جارٍ تحميل الصور...'),
          error: (Failure failure) => ErrorView(
            title: 'تعذّر تحميل الصور',
            message: failure.message,
          ),
          loaded: (PhotosData data) => Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Column(
                  children: <Widget>[
                    _GalleryToolbar(data: data, photoStorageService: photoStorageService),
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
                        crossAxisCount: 5,
                        selectedPhotoId: data.selectedPhoto?.id,
                        resolveSignedUrl: (String path) =>
                            photoStorageService.getSignedUrl(path).then(
                              (ResultOf<String> r) => r.getOrNull(),
                            ),
                        onPhotoTap: (SitePhoto photo) =>
                            context.read<PhotosCubit>().selectPhoto(photo),
                      ),
                    ),
                  ],
                ),
              ),
              if (data.selectedPhoto != null)
                SizedBox(
                  width: 340,
                  child: PhotoDetailsPanel(
                    photo: data.selectedPhoto!,
                    photoStorageService: photoStorageService,
                    onClose: () => context.read<PhotosCubit>().selectPhoto(null),
                    onDelete: () => context.read<PhotosCubit>().deletePhoto(data.selectedPhoto!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GalleryToolbar extends StatelessWidget {
  const _GalleryToolbar({required this.data, required this.photoStorageService});

  final PhotosData data;
  final PhotoStorageService photoStorageService;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AvahiSpacing.md,
        vertical: AvahiSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: 'الكل',
                    selected: data.filterEntityType == null,
                    onTap: () => context.read<PhotosCubit>().setFilterEntityType(null),
                  ),
                  ...RelatedEntityType.values.map(
                    (RelatedEntityType type) => Padding(
                      padding: const EdgeInsets.only(right: AvahiSpacing.xs),
                      child: _FilterChip(
                        label: type.displayNameAr,
                        selected: data.filterEntityType == type,
                        onTap: () => context.read<PhotosCubit>().setFilterEntityType(type),
                      ),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.md),
                  FilterChip(
                    label: const Text('صوري فقط'),
                    selected: data.filterUploadedByMeOnly,
                    onSelected: (bool value) =>
                        context.read<PhotosCubit>().setFilterUploadedByMeOnly(value),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'بحث في التعليقات/الوسوم...',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (String q) => context.read<PhotosCubit>().setSearchQuery(q),
            ),
          ),
          const SizedBox(width: AvahiSpacing.sm),
          AvahiButton(
            label: 'إضافة صور',
            icon: Icons.add_photo_alternate_outlined,
            onPressed: () => context.pushNamed(
              RouteNames.photosCamera,
              extra: context.read<PhotosCubit>(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AvahiSpacing.xs),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
