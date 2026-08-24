import 'package:equatable/equatable.dart';

/// نقطة اتجاه واحدة ضمن [PlatformUsageSnapshot.dailyActiveTenantsTrend]
/// — بنفس فلسفة `AttendanceTrendPoint` في `features/analytics/`.
class PlatformUsageTrendPoint extends Equatable {
  const PlatformUsageTrendPoint({
    required this.date,
    required this.activeTenantsCount,
  });

  final DateTime date;
  final int activeTenantsCount;

  @override
  List<Object?> get props => <Object?>[date, activeTenantsCount];
}

/// لقطة حالة استخدام المنصّة كاملة في لحظة معيّنة — تُغذّي
/// `usage_monitor.dart`. 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم (بيانات تجريبية بالكامل): لا يوجد بعد أي بنية تحتية
/// لمراقبة/قياس فعلية (APM) متصلة بالتطبيق (خارج نطاق Prompt 28،
/// اقتصاراً على `lib/features/platform_admin/` وEdge Function واحدة
/// جديدة فقط كما ورد صراحة في السياق العام لهذا الـ Prompt: "بيانات
/// تجريبية إن لم يوجد مصدر حقيقي بعد" لـ `usage_monitor.dart` تحديداً)
/// — القيم هنا مولَّدة حتمياً (Deterministic، بدون `Random()`) عبر
/// `PlatformAdminRepositoryImpl._buildMockUsageSnapshot` استناداً إلى
/// عدد الشركات/الأعضاء الحقيقي فقط (وليست عشوائية بحتة)، لتبقى قابلة
/// للاستبدال لاحقاً بمصدر حقيقي (Prompt مستقبلي مخصّص لبنية مراقبة
/// فعلية) دون تغيير شكل [PlatformUsageSnapshot] نفسه.
class PlatformUsageSnapshot extends Equatable {
  const PlatformUsageSnapshot({
    required this.capturedAt,
    required this.totalTenants,
    required this.activeTenants,
    required this.totalUsers,
    required this.activeUsersToday,
    required this.totalStorageGb,
    required this.apiRequestsToday,
    required this.avgResponseTimeMs,
    required this.errorRatePercent,
    required this.dailyActiveTenantsTrend,
  });

  final DateTime capturedAt;
  final int totalTenants;
  final int activeTenants;
  final int totalUsers;
  final int activeUsersToday;
  final double totalStorageGb;
  final int apiRequestsToday;
  final int avgResponseTimeMs;
  final double errorRatePercent;
  final List<PlatformUsageTrendPoint> dailyActiveTenantsTrend;

  @override
  List<Object?> get props => <Object?>[
        capturedAt,
        totalTenants,
        activeTenants,
        totalUsers,
        activeUsersToday,
        totalStorageGb,
        apiRequestsToday,
        avgResponseTimeMs,
        errorRatePercent,
        dailyActiveTenantsTrend,
      ];
}
