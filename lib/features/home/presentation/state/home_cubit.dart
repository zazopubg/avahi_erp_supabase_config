import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/usecases/attendance/get_today_attendance_usecase.dart';
import '../../../../domain/usecases/notifications/get_notifications_usecase.dart';
import '../../../../domain/usecases/notifications/mark_as_read_usecase.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/tasks/get_my_tasks_usecase.dart';
import 'home_state.dart';

/// `Cubit` ميزة الرئيسية — يجمّع أربعة مصادر بيانات مختلفة (مشاريع،
/// مهام، حضور، إشعارات) في [HomeSummary] واحد يستهلكه `home_screen.dart`
/// وشاشات الأدوار الثلاث (`worker_home.dart`/`supervisor_home.dart`/
/// `manager_home.dart`) دون أن تستدعي أي منها أي `UseCase` مباشرة —
/// بنفس نمط `AuthCubit` (الجهة الوحيدة في ميزتها التي تستدعي `domain/`).
///
/// ⚠️ استهلاك أولي مبسّط (كما هو محدد في Prompt 14): كل استدعاء فرعي
/// (مشروع/مهام/حضور/إشعارات) يُعالَج بتساهل عبر دوال `_loadXxx` خاصة —
/// فشل مصدر واحد لا يُسقط الشاشة كاملة بحالة [HomeError]، بل يُترك ذلك
/// الجزء فارغاً/`null` (نفس نمط `AuthCubit._resolveMembership` عند
/// تجميع شركات عضويات متعددة وتجاهل فشل جلب شركة واحدة منها). التفاصيل
/// الكاملة (بث لحظي، أخطاء لكل قسم على حدة...) تُبنى لاحقاً ضمن ميزة
/// كل مصدر (`features/attendance/`، `features/tasks/`،
/// `features/notifications/`).
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetTodayAttendanceUsecase getTodayAttendanceUsecase,
    required GetMyTasksUsecase getMyTasksUsecase,
    required GetNotificationsUsecase getNotificationsUsecase,
    required MarkAsReadUsecase markAsReadUsecase,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getTodayAttendanceUsecase = getTodayAttendanceUsecase,
        _getMyTasksUsecase = getMyTasksUsecase,
        _getNotificationsUsecase = getNotificationsUsecase,
        _markAsReadUsecase = markAsReadUsecase,
        super(const HomeInitial());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetTodayAttendanceUsecase _getTodayAttendanceUsecase;
  final GetMyTasksUsecase _getMyTasksUsecase;
  final GetNotificationsUsecase _getNotificationsUsecase;
  final MarkAsReadUsecase _markAsReadUsecase;

  /// تُستدعى من `home_screen.dart` فور توفر [AppUser] من `AuthCubit.state`
  /// (`AuthAuthenticated`) — تجلب كل مصادر ملخص اليوم تسلسلياً (وليس
  /// عبر `Future.wait` متوازٍ) عمداً: تحديد [Project] الحالي شرط مسبق
  /// لجلب حضور اليوم تحديداً ([GetTodayAttendanceUsecase] يتطلب
  /// `projectId` إلزامياً)، فيبقى التسلسل الفعلي أبسط وأوضح من تقسيم
  /// الاستدعاءات المتوازية إلى مجموعتين تعتمد إحداهما على الأخرى.
  Future<void> loadHome(AppUser user) async {
    emit(const HomeLoading());

    final Project? currentProject = await _loadCurrentProject(user.userId);

    final List<Task> tasks = await _loadTasks(
      userId: user.userId,
      projectId: currentProject?.id,
    );

    final AttendanceRecord? todayAttendance = currentProject == null
        ? null
        : await _loadTodayAttendance(
            userId: user.userId,
            projectId: currentProject.id,
          );

    final List<AppNotification> unreadNotifications =
        await _loadUnreadNotifications(user.userId);

    emit(
      HomeLoaded(
        HomeSummary(
          currentProject: currentProject,
          todayAttendance: todayAttendance,
          tasks: tasks,
          unreadNotifications: unreadNotifications,
        ),
      ),
    );
  }

  /// سحب للتحديث (Pull to Refresh) — نفس منطق [loadHome] تماماً (يمر
  /// عبر [HomeLoading] مجدداً)؛ الاسم المنفصل فقط لتوضيح نية الاستدعاء
  /// من `RefreshIndicator.onRefresh` في شاشات الأدوار الثلاث.
  Future<void> refresh(AppUser user) => loadHome(user);

  /// تعليم إشعار واحد كمقروء وإزالته محلياً من [HomeSummary.unreadNotifications]
  /// دون إعادة جلب كامل الملخص من الشبكة (تحديث متفائل - Optimistic
  /// Update). لا شيء يحدث إن كانت الحالة الحالية ليست [HomeLoaded] أو
  /// إن فشل الاستدعاء (يبقى الإشعار ظاهراً — المستخدم يمكنه إعادة
  /// المحاولة بالضغط عليه مجدداً).
  Future<void> markNotificationAsRead(String notificationId) async {
    final HomeState current = state;
    if (current is! HomeLoaded) return;

    final ResultOf<AppNotification> result = await _markAsReadUsecase(
      notificationId,
    );
    result.fold(
      (Failure _) {},
      (AppNotification _) {
        final List<AppNotification> updated = current.summary
            .unreadNotifications
            .where((AppNotification n) => n.id != notificationId)
            .toList(growable: false);
        emit(
          HomeLoaded(
            current.summary.copyWith(unreadNotifications: updated),
          ),
        );
      },
    );
  }

  /// يجلب مشاريع المستخدم ويختار "المشروع الحالي": أول مشروع بحالة
  /// [ProjectStatus.active]، أو أول مشروع مطلقاً إن لم يوجد أي مشروع
  /// نشط ضمن قائمته (أفضل من عدم اختيار شيء، حتى لو كان مؤرشفاً/مكتملاً
  /// — لا يزال أفضل سياق افتراضي متاح لملخص اليوم).
  Future<Project?> _loadCurrentProject(String userId) async {
    final ResultOf<List<Project>> result = await _getMyProjectsUsecase(
      userId,
    );
    return result.fold(
      (Failure _) => null,
      (List<Project> projects) {
        if (projects.isEmpty) return null;
        return projects.firstWhere(
          (Project p) => p.status.isActive,
          orElse: () => projects.first,
        );
      },
    );
  }

  Future<List<Task>> _loadTasks({
    required String userId,
    String? projectId,
  }) async {
    final ResultOf<List<Task>> result = await _getMyTasksUsecase(
      userId: userId,
      projectId: projectId,
    );
    return result.fold(
      (Failure _) => const <Task>[],
      (List<Task> tasks) => tasks,
    );
  }

  Future<AttendanceRecord?> _loadTodayAttendance({
    required String userId,
    required String projectId,
  }) async {
    final ResultOf<AttendanceRecord?> result =
        await _getTodayAttendanceUsecase(
      userId: userId,
      projectId: projectId,
    );
    return result.fold(
      (Failure _) => null,
      (AttendanceRecord? record) => record,
    );
  }

  Future<List<AppNotification>> _loadUnreadNotifications(
    String userId,
  ) async {
    final ResultOf<List<AppNotification>> result =
        await _getNotificationsUsecase(userId: userId, unreadOnly: true);
    return result.fold(
      (Failure _) => const <AppNotification>[],
      (List<AppNotification> notifications) => notifications,
    );
  }
}
