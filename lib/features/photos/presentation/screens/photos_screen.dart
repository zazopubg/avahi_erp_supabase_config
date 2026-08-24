import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../data/storage/photo_storage_service.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../ui/widgets/common/error_view.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/photos_cubit.dart';
import '../state/photos_state.dart';
import 'desktop/photo_gallery.dart';
import 'mobile/my_photos_screen.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.photos` (`/photos`) — بنفس
/// نمط `TasksScreen`/`AttendanceScreen` تماماً (`Cubit` واحد
/// [PhotosCubit] يُقدَّم محلياً عبر `sl<PhotosCubit>()..loadInitial(user, onlyMine: true)`،
/// ثم يتفرّع العرض حسب [ShellMode] فقط): [MyPhotosScreen] للهاتف
/// (< 600، صور المستخدم الحالي فقط افتراضياً) و[PhotoGallery] لما هو
/// أوسع (لوحي/سطح مكتب، كل صور المشروع افتراضياً مع فلاتر متقدمة).
///
/// `/photos/camera` و`/photos/attach` (Prompt 18) لهما نقطتا دخول
/// مستقلتان تماماً خارج هذه الشاشة (خارج `ShellRoute` أصلاً) — تستقبلان
/// نفس نسخة [PhotosCubit] هذه عبر `extra` في `go_router` بدل إنشاء
/// نسخة جديدة، بنفس فلسفة `RouteNames.tasksBoard` المنفصلة عن
/// `TasksScreen` (لكن هناك بنسخة `Cubit` منفصلة تماماً، بينما هنا
/// بنفس النسخة عمداً لتفادي فقدان حالة `PhotosData.project`/`currentUser`
/// المحمَّلة أصلاً بين خطوتَي الالتقاط والربط).
class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<PhotosCubit>(
              create: (_) => sl<PhotosCubit>()..loadInitial(user, onlyMine: true),
              child: const _PhotosBody(),
            );
          },
        );
      },
    );
  }
}

class _PhotosBody extends StatelessWidget {
  const _PhotosBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotosCubit, PhotosState>(
      builder: (BuildContext context, PhotosState state) {
        return state.maybeWhen<Widget>(
          orElse: () => context.shellMode.isMobile
              ? MyPhotosScreen(photoStorageService: sl<PhotoStorageService>())
              : PhotoGallery(photoStorageService: sl<PhotoStorageService>()),
          loading: () =>
              const Scaffold(body: LoadingIndicator(label: 'جارٍ تحميل الصور...')),
          error: (Failure failure) => Scaffold(
            appBar: AppBar(title: const Text('الصور')),
            body: ErrorView(title: 'تعذّر تحميل الصور', message: failure.message),
          ),
        );
      },
    );
  }
}
