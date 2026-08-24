import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
// TODO: استورد حالات الاستخدام (usecases) الفعلية لميزتك، بنفس نمط
// EquipmentCubit/DocumentsCubit/PunchCubit، مثال:
// import '../../../../domain/usecases/__feature_name__/get_all___feature_name___usecase.dart';
import '__feature_name___state.dart';

/// `Cubit` ميزة `features/__feature_name__/` — يقود كل شاشات الميزة معاً
/// (`screens/mobile/`, `screens/desktop/`) عبر [__FeatureName__Data]
/// واحدة مجمّعة، بنفس فلسفة `EquipmentCubit`/`DocumentsCubit`/
/// `PunchCubit` تماماً.
///
/// ⚠️ قرار تصميم قياسي في كل ميزات المشروع: هذا الـ Cubit **لا يكتب
/// مباشرة** لأي مصدر بيانات — كل قراءة/كتابة تمر عبر UseCase تستدعي
/// عقد Repository في `domain/repositories/`. الكتابة الفعلية (محلي
/// أولاً ← Outbox ← مزامنة خلفية) تُدار بالكامل داخل
/// `data/repositories_impl/__feature_name___repository_impl.dart` —
/// انظر docs/architecture/06_offline_first.md قبل إضافة أي منطق
/// Offline هنا مباشرة.
class __FeatureName__Cubit extends Cubit<__FeatureName__State> {
  __FeatureName__Cubit({
    // TODO: أضف حالات الاستخدام (usecases) الفعلية هنا كباراميترات
    // مُلزَمة (required)، واحقنها عبر core/di/features_module.dart —
    // لا إنشاء مباشر (Repository()/UseCase()) داخل هذا الملف إطلاقاً.
  }) : super(const __FeatureName__Loading());

  /// يُستدعى عند دخول أول شاشة في الميزة (`screens/mobile/*_screen.dart`
  /// أو `screens/desktop/*_screen.dart` — نقطة الدخول الموحّدة).
  Future<void> loadInitial(AppUser user) async {
    emit(const __FeatureName__Loading());

    // TODO: استبدل هذا بالاستدعاء الفعلي لحالة/حالات الاستخدام،
    // بنفس نمط EquipmentCubit.loadInitial:
    //
    // final ResultOf<List<Item>> result = await _getAllItemsUsecase();
    // result.fold(
    //   (Failure failure) => emit(__FeatureName__Error(failure)),
    //   (List<Item> items) => emit(
    //     __FeatureName__Loaded(
    //       __FeatureName__Data(currentUser: user, items: items),
    //     ),
    //   ),
    // );

    emit(__FeatureName__Loaded(__FeatureName__Data(currentUser: user)));
  }

  /// سحب للتحديث — يعيد تحميل القائمة الرئيسية فقط دون إعادة ضبط
  /// كامل الحالة (بنفس نمط `EquipmentCubit.refresh`).
  Future<void> refresh() async {
    final __FeatureName__Data? current = state.dataOrNull;
    if (current == null) return;

    emit(__FeatureName__Loaded(current.copyWith(isRefreshing: true)));

    // TODO: استدعاء فعلي لإعادة الجلب، ثم:
    final __FeatureName__Data latest = state.dataOrNull ?? current;
    emit(__FeatureName__Loaded(latest.copyWith(isRefreshing: false)));
  }

  /// مثال لتحديث حقل بحث/فلترة محلي في [__FeatureName__Data] دون أي
  /// استدعاء شبكة — نمط شائع عبر كل الميزات لفلترة جانب العميل.
  void updateSearchQuery(String query) {
    final __FeatureName__Data? current = state.dataOrNull;
    if (current == null) return;
    emit(__FeatureName__Loaded(current.copyWith(searchQuery: query)));
  }
}
