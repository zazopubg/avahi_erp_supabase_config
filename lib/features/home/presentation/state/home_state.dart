import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/task.dart';

/// حالة `HomeCubit` — Union Type مكتوب يدوياً (`sealed class` + تفريغ
/// أنماط `switch`)، بنفس نمط `features/auth/presentation/state/auth_state.dart`
/// تماماً (بلا `freezed`، اتساقاً مع القرار المعماري الموثَّق هناك).
sealed class HomeState {
  const HomeState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الأربع إلزامية.
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(HomeSummary summary) loaded,
    required T Function(Failure failure) error,
  }) {
    final HomeState state = this;
    return switch (state) {
      HomeInitial() => initial(),
      HomeLoading() => loading(),
      HomeLoaded(:final summary) => loaded(summary),
      HomeError(:final failure) => error(failure),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي كقيمة
  /// افتراضية لأي حالة غير مُمرَّرة.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(HomeSummary summary)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      initial: initial ?? orElse,
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }
}

/// الحالة الابتدائية قبل أول استدعاء لـ `HomeCubit.loadHome`.
final class HomeInitial extends HomeState {
  const HomeInitial();
}

/// جارٍ تحميل ملخص اليوم (مشروع/مهام/حضور/إشعارات).
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// ملخص اليوم جاهز للعرض.
final class HomeLoaded extends HomeState {
  const HomeLoaded(this.summary);

  final HomeSummary summary;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً (حالة استثنائية — انظر توثيق
/// التساهل في `home_cubit.dart`: فشل مصدر واحد فقط لا يصل لهذه الحالة).
final class HomeError extends HomeState {
  const HomeError(this.failure);

  final Failure failure;
}

/// ملخص بيانات الشاشة الرئيسية المجمّعة من عدة مصادر — استهلاك أولي
/// مبسّط (كما هو محدد في Prompt 14)؛ التفاصيل الكاملة لكل مصدر تُبنى
/// لاحقاً ضمن ميزته الخاصة: `features/attendance/` (Prompt 15)،
/// `features/tasks/` (Prompt 16)، `features/notifications/` (Prompt 23).
class HomeSummary {
  const HomeSummary({
    required this.tasks,
    required this.unreadNotifications,
    this.currentProject,
    this.todayAttendance,
  });

  /// المشروع الحالي للمستخدم — أول مشروع نشط ضمن مشاريعه، أو أول
  /// مشروع مطلقاً إن لم يوجد أي مشروع بحالة [ProjectStatus.active]
  /// (انظر `HomeCubit._loadCurrentProject`)، أو `null` إن لم يكن
  /// عضواً في أي مشروع بعد.
  final Project? currentProject;

  /// سجل حضور اليوم ضمن [currentProject]، أو `null` إن لم يُسجَّل
  /// حضور بعد اليوم (أو لا يوجد [currentProject] أصلاً).
  final AttendanceRecord? todayAttendance;

  final List<Task> tasks;

  /// الإشعارات غير المقروءة (غير محدودة العدد هنا — [latestUnreadNotifications]
  /// هي من تقتصر العرض على آخر 3، بينما هذه القائمة الكاملة تُستخدم
  /// أيضاً لحساب [unreadCount] الكامل).
  final List<AppNotification> unreadNotifications;

  bool get hasCheckedInToday => todayAttendance != null;

  bool get hasCheckedOutToday => todayAttendance?.checkOutAt != null;

  int get pendingTasksCount =>
      tasks.where((Task t) => !t.status.isDone).length;

  int get unreadCount => unreadNotifications.length;

  /// آخر 3 إشعارات غير مقروءة فقط — ما تعرضه `alerts_section.dart`
  /// فعلياً في الشاشة الرئيسية (القائمة الكاملة تبقى ضمن [unreadNotifications]).
  List<AppNotification> get latestUnreadNotifications =>
      unreadNotifications.take(3).toList(growable: false);

  HomeSummary copyWith({
    Project? currentProject,
    AttendanceRecord? todayAttendance,
    List<Task>? tasks,
    List<AppNotification>? unreadNotifications,
  }) {
    return HomeSummary(
      currentProject: currentProject ?? this.currentProject,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      tasks: tasks ?? this.tasks,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
    );
  }
}
