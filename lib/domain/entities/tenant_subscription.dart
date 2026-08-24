import 'package:equatable/equatable.dart';

/// حالة اشتراك مستأجر (شركة) واحد بخطة [SubscriptionPlan] محدَّدة —
/// يُستهلَك من `billing_overview.dart`. 🆕 (Prompt 28)
///
/// ⚠️ نفس قرار التصميم الموثَّق في `SubscriptionPlan` (بيانات ثابتة/
/// مولَّدة، بانتظار جدول `tenant_subscriptions` حقيقي مستقبلاً) —
/// [companyId] هنا يبقى حقيقياً (مطابق لـ `companies.id` فعلي عبر
/// [IPlatformAdminRepository.getAllCompanies]) حتى إن كانت تفاصيل
/// الاشتراك نفسها مولَّدة حالياً.
enum TenantSubscriptionStatus {
  /// فترة تجريبية سارية.
  trial,

  /// اشتراك نشط ومدفوع.
  active,

  /// دفعة متأخرة (يحتاج متابعة).
  pastDue,

  /// اشتراك مُلغى (لم يعد نشطاً).
  cancelled;

  bool get isTrial => this == TenantSubscriptionStatus.trial;
  bool get isActive => this == TenantSubscriptionStatus.active;
  bool get isPastDue => this == TenantSubscriptionStatus.pastDue;
  bool get isCancelled => this == TenantSubscriptionStatus.cancelled;
}

class TenantSubscription extends Equatable {
  const TenantSubscription({
    required this.companyId,
    required this.planId,
    required this.status,
    required this.startedAt,
    required this.currentPeriodEndsAt,
    required this.mrrUsd,
  });

  final String companyId;
  final String planId;
  final TenantSubscriptionStatus status;
  final DateTime startedAt;
  final DateTime currentPeriodEndsAt;

  /// الإيراد الشهري المتكرر (Monthly Recurring Revenue) لهذا المستأجر
  /// وحده بالدولار الأمريكي.
  final double mrrUsd;

  TenantSubscription copyWith({
    String? companyId,
    String? planId,
    TenantSubscriptionStatus? status,
    DateTime? startedAt,
    DateTime? currentPeriodEndsAt,
    double? mrrUsd,
  }) {
    return TenantSubscription(
      companyId: companyId ?? this.companyId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      currentPeriodEndsAt: currentPeriodEndsAt ?? this.currentPeriodEndsAt,
      mrrUsd: mrrUsd ?? this.mrrUsd,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        companyId,
        planId,
        status,
        startedAt,
        currentPeriodEndsAt,
        mrrUsd,
      ];
}
