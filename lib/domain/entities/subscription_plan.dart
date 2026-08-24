import 'package:equatable/equatable.dart';

/// خطة اشتراك واحدة متاحة على مستوى المنصّة كاملة (عابرة للمستأجرين)،
/// تُدار من `plans_management.dart`. 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم (Dart نقي بلا جدول DB مطابق بعد): لا يوجد حالياً جدول
/// `subscription_plans` ضمن `backend/supabase/migrations/` (خارج نطاق
/// Prompt 28 هذا — يقتصر على `lib/features/platform_admin/` وEdge
/// Function واحدة جديدة فقط، انظر السياق العام للـ Prompt). بيانات
/// الخطط هنا ثابتة (Static) مصدرها
/// `PlatformAdminRepositoryImpl._staticPlans`، بنفس فلسفة "بيانات
/// تجريبية إن لم يوجد مصدر حقيقي بعد" المُقرَّة صراحة لـ
/// `usage_monitor.dart`/`error_logs.dart` في نفس الـ Prompt — تُستبدل
/// لاحقاً بجدول حقيقي + Cubit مطابق للنمط العام (`ICompanyRepository`
/// إلخ) عند تخصيص Prompt مستقبلي لنظام الفوترة الفعلي.
class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.monthlyPriceUsd,
    required this.maxUsers,
    required this.maxProjects,
    required this.maxStorageGb,
    required this.features,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final String nameAr;
  final double monthlyPriceUsd;

  /// `-1` يعني بلا حد أقصى (خطة Enterprise).
  final int maxUsers;

  /// `-1` يعني بلا حد أقصى.
  final int maxProjects;

  /// `-1` يعني بلا حد أقصى.
  final int maxStorageGb;

  final List<String> features;

  /// صحيح لخطة واحدة فقط تُبرَز بصرياً كـ "الأكثر شيوعاً" في
  /// `plans_management.dart`.
  final bool isPopular;

  bool get hasUnlimitedUsers => maxUsers < 0;
  bool get hasUnlimitedProjects => maxProjects < 0;
  bool get hasUnlimitedStorage => maxStorageGb < 0;

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? nameAr,
    double? monthlyPriceUsd,
    int? maxUsers,
    int? maxProjects,
    int? maxStorageGb,
    List<String>? features,
    bool? isPopular,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      monthlyPriceUsd: monthlyPriceUsd ?? this.monthlyPriceUsd,
      maxUsers: maxUsers ?? this.maxUsers,
      maxProjects: maxProjects ?? this.maxProjects,
      maxStorageGb: maxStorageGb ?? this.maxStorageGb,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        nameAr,
        monthlyPriceUsd,
        maxUsers,
        maxProjects,
        maxStorageGb,
        features,
        isPopular,
      ];
}
