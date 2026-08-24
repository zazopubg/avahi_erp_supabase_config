import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/local_settings_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/sync/sync_scheduler.dart';
import '../../../../domain/enums/sync_state.dart';
import 'settings_state.dart';

/// تصنيفات الإشعارات الثابتة المدعومة — مصدر الحقيقة الوحيد المستهلَك
/// من `notification_settings.dart` (تسمية العرض) و`SettingsCubit`
/// (مفاتيح `LocalSettingsService`). إضافة تصنيف جديد لاحقاً (مثال: عند
/// بناء ميزة جديدة) يتطلب فقط إضافة ثابت هنا — لا تعديل مطلوب على
/// `LocalSettingsService` نفسها (مفتاحها مبني ديناميكياً من اسم
/// التصنيف).
abstract final class NotificationCategories {
  static const String taskUpdates = 'task_updates';
  static const String attendanceReminders = 'attendance_reminders';
  static const String leaveApprovals = 'leave_approvals';
  static const String reportReviews = 'report_reviews';
  static const String equipmentAlerts = 'equipment_alerts';

  static const List<String> all = <String>[
    taskUpdates,
    attendanceReminders,
    leaveApprovals,
    reportReviews,
    equipmentAlerts,
  ];
}

/// `Cubit` ميزة `features/settings/` — يقود شاشتي `sync_settings.dart`
/// و`notification_settings.dart` تحديداً (البيانات الوحيدتان اللتان
/// تحتاجان حالة تفاعلية/بثاً حياً)، بخلاف `glove_mode_settings.dart`/
/// `display_settings.dart`/`language_settings.dart` التي تستهلك
/// `GloveModeCubit`/`DarkModeCubit`/`TextScaleCubit`/`LocaleCubit`
/// (`ui/modes/`) مباشرة عبر `context.read`/`context.watch` — انظر
/// توثيق القرار الكامل في `settings_screen.dart` حول توزيع المسؤولية
/// هذا بين هذا الـ Cubit وتلك الـ Cubits الأربعة عابرة التطبيق كاملاً.
///
/// ⚠️ `profile_screen.dart`/`about_screen.dart` أيضاً لا تحتاجان هذا
/// الـ Cubit إطلاقاً: الأولى تقرأ `AuthCubit.state` مباشرة (نفس نمط
/// `home_screen.dart`)، والثانية تعرض `AppConfig.instance` الثابتة —
/// كلتاهما بلا أي حالة تفاعلية خاصة بهما تستحق إضافتها لـ [SettingsData].
class SettingsCubit extends Cubit<SettingsData> {
  SettingsCubit({
    required LocalSettingsService settingsService,
    required SyncScheduler syncScheduler,
    required NotificationService notificationService,
  })  : _settingsService = settingsService,
        _syncScheduler = syncScheduler,
        _notificationService = notificationService,
        super(const SettingsData());

  final LocalSettingsService _settingsService;
  final SyncScheduler _syncScheduler;
  final NotificationService _notificationService;

  StreamSubscription<SyncState>? _syncStateSubscription;
  StreamSubscription<int>? _pendingCountSubscription;

  /// يُستدعى عند دخول `sync_settings.dart` **أو** `notification_settings.dart`
  /// (أيّهما أولاً — كلتاهما تستدعيانه بأمان، انظر الحارس
  /// `if (isClosed) return;` وعدم تكديس الاشتراكات في [_subscribeToSync]
  /// أدناه) لتحميل كل الحالة المحلية المحفوظة + بدء الاشتراك اللحظي
  /// بحالة `SyncScheduler`.
  void loadInitial() {
    final Map<String, bool> categories = <String, bool>{
      for (final String category in NotificationCategories.all)
        category: _settingsService.readNotificationCategoryEnabled(category),
    };

    emit(
      state.copyWith(
        syncState: _syncScheduler.currentState,
        isSyncAutoEnabled: _settingsService.readSyncAutoEnabled(),
        lastSuccessfulSyncAt: _syncScheduler.lastSuccessfulSyncAt,
        notificationCategories: categories,
        notificationPermissionGranted: _notificationService.isPermissionGranted,
        notificationPermissionDenied: _notificationService.isPermissionDenied,
      ),
    );

    _subscribeToSync();
  }

  void _subscribeToSync() {
    _syncStateSubscription?.cancel();
    _syncStateSubscription = _syncScheduler.stateStream.listen((SyncState s) {
      emit(
        state.copyWith(
          syncState: s,
          lastSuccessfulSyncAt: s == SyncState.synced
              ? _syncScheduler.lastSuccessfulSyncAt
              : null,
        ),
      );
    });

    _pendingCountSubscription?.cancel();
    _pendingCountSubscription = _syncScheduler.watchPendingCount().listen(
      (int count) => emit(state.copyWith(pendingOutboxCount: count)),
    );
  }

  // ── المزامنة ─────────────────────────────────────────────────────

  /// زر "مزامنة الآن" — يبقى متاحاً حتى لو [isSyncAutoEnabled] معطَّلة
  /// (انظر توثيق القرار في `SyncScheduler.triggerNow`).
  Future<void> triggerSyncNow() async {
    if (state.isSyncTriggeringNow) return;
    emit(state.copyWith(isSyncTriggeringNow: true));
    await _syncScheduler.triggerNow();
    emit(state.copyWith(isSyncTriggeringNow: false));
  }

  Future<void> setSyncAutoEnabled(bool enabled) async {
    if (enabled) {
      await _syncScheduler.resumeAutomatic();
    } else {
      await _syncScheduler.pauseAutomatic();
    }
    emit(state.copyWith(isSyncAutoEnabled: enabled));
  }

  // ── الإشعارات ────────────────────────────────────────────────────

  Future<void> setNotificationCategoryEnabled(
    String category,
    bool enabled,
  ) async {
    await _settingsService.saveNotificationCategoryEnabled(category, enabled);
    final Map<String, bool> updated = Map<String, bool>.of(
      state.notificationCategories,
    )..[category] = enabled;
    emit(state.copyWith(notificationCategories: updated));
  }

  /// يطلب إذن الإشعارات من المتصفح صراحة — يُستدعى فقط عبر ضغطة
  /// مستخدم مباشرة على زر في `notification_settings.dart` (طلب إذن
  /// من داخل معالج ضغط زر شرط أساسي في أغلب المتصفحات لتفادي رفض
  /// تلقائي بسبب غياب "تفاعل مستخدم" (User Gesture)).
  Future<void> requestNotificationPermission() async {
    emit(state.copyWith(isRequestingNotificationPermission: true));
    final bool granted = await _notificationService.requestPermission();
    await _settingsService.savePushPermissionRequested(true);
    emit(
      state.copyWith(
        notificationPermissionGranted: granted,
        notificationPermissionDenied: !granted,
      ),
    );
  }

  @override
  Future<void> close() {
    _syncStateSubscription?.cancel();
    _pendingCountSubscription?.cancel();
    return super.close();
  }
}
