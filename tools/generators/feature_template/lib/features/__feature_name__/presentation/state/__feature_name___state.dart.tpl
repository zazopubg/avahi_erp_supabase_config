import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
// TODO: عدّل هذا الاستيراد لكيان الميزة الفعلي بدل هذا المثال
// import '../../../../domain/entities/__FeatureName___entity.dart';

/// حالة `__FeatureName__Cubit` الكاملة — Union Type مكتوب يدوياً، بنفس
/// نمط كل ميزات المشروع الحالية (`EquipmentState`, `DocumentsState`,
/// `PunchState`...): لا `freezed`، ثلاث حالات فقط.
///
/// راجع docs/architecture/01_overview.md#إدارة-الحالة-عبر-cubit قبل
/// تعديل هذا النمط.
sealed class __FeatureName__State {
  const __FeatureName__State();

  T when<T>({
    required T Function() loading,
    required T Function(__FeatureName__Data data) loaded,
    required T Function(Failure failure) error,
  }) {
    final __FeatureName__State state = this;
    return switch (state) {
      __FeatureName__Loading() => loading(),
      __FeatureName__Loaded(:final data) => loaded(data),
      __FeatureName__Error(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(__FeatureName__Data data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [__FeatureName__Data] الحالية إن كانت الحالة
  /// [__FeatureName__Loaded]، أو `null` — مختصر مفيد للشاشات.
  __FeatureName__Data? get dataOrNull => maybeWhen<__FeatureName__Data?>(
        orElse: () => null,
        loaded: (__FeatureName__Data d) => d,
      );
}

/// جارٍ التحميل الأولي.
final class __FeatureName__Loading extends __FeatureName__State {
  const __FeatureName__Loading();
}

/// جاهزة لعرض كل شاشات الميزة — الفرق بين `screens/mobile/` و
/// `screens/desktop/` بصري بحت حسب `ShellMode` (انظر
/// docs/architecture/05_responsive_web.md)، لا حالة منفصلة لكل منهما.
final class __FeatureName__Loaded extends __FeatureName__State {
  const __FeatureName__Loaded(this.data);

  final __FeatureName__Data data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً — يعتمد `ErrorView`/`Retry` في
/// الشاشة لإعادة `__FeatureName__Cubit.loadInitial`.
final class __FeatureName__Error extends __FeatureName__State {
  const __FeatureName__Error(this.failure);

  final Failure failure;
}

/// حزمة بيانات الميزة المجمّعة — يحملها [__FeatureName__Loaded] وحدها.
///
/// TODO: استبدل الحقول أدناه ببيانات ميزتك الفعلية. أبقِ `currentUser`
/// دوماً (كل الميزات الحالية تحتاجه لأغراض RLS/الصلاحيات في الواجهة).
class __FeatureName__Data {
  const __FeatureName__Data({
    required this.currentUser,
    this.items = const <dynamic>[],
    this.isRefreshing = false,
    this.searchQuery = '',
  });

  final AppUser currentUser;

  // TODO: بدّل `dynamic` بنوع كيان الميزة الفعلي.
  final List<dynamic> items;

  final bool isRefreshing;
  final String searchQuery;

  bool get hasActiveFilters => searchQuery.trim().isNotEmpty;

  __FeatureName__Data copyWith({
    AppUser? currentUser,
    List<dynamic>? items,
    bool? isRefreshing,
    String? searchQuery,
  }) {
    return __FeatureName__Data(
      currentUser: currentUser ?? this.currentUser,
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
