import 'package:equatable/equatable.dart';

/// إحصائيات مجمَّعة لمستأجر (شركة) واحد — مبنية من استعلامات حقيقية
/// عابرة للجداول (`company_members`/`projects`/`documents`/`photos`)
/// وليست عموداً مخزَّناً في `companies` نفسه. 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم ([storageUsedBytes] مجموع حقيقي، لا تقدير): يُجمَع من
/// عمود `file_size_bytes` الحقيقي الموجود فعلاً على `documents`
/// (Prompt 21) و`photos` (Prompt 18) — بخلاف [PlatformUsageSnapshot]/
/// [SubscriptionPlan] وغيرها ضمن هذه الميزة نفسها، لا مصدر بيانات هنا
/// مفقوداً يستدعي بيانات تجريبية. انظر توثيق القرار الكامل في
/// `PlatformAdminRepositoryImpl.getTenantStats`.
class TenantStats extends Equatable {
  const TenantStats({
    required this.companyId,
    required this.membersCount,
    required this.activeMembersCount,
    required this.projectsCount,
    required this.activeProjectsCount,
    required this.storageUsedBytes,
    this.lastActivityAt,
  });

  final String companyId;
  final int membersCount;
  final int activeMembersCount;
  final int projectsCount;
  final int activeProjectsCount;

  /// مجموع `file_size_bytes` لكل مستندات وصور هذه الشركة (بايت).
  final int storageUsedBytes;

  /// آخر توقيت نشاط مرصود لهذه الشركة (أحدث `updated_at` عبر
  /// `company_members`)، أو `null` إن تعذّر تحديده.
  final DateTime? lastActivityAt;

  static const TenantStats empty = TenantStats(
    companyId: '',
    membersCount: 0,
    activeMembersCount: 0,
    projectsCount: 0,
    activeProjectsCount: 0,
    storageUsedBytes: 0,
  );

  TenantStats copyWith({
    String? companyId,
    int? membersCount,
    int? activeMembersCount,
    int? projectsCount,
    int? activeProjectsCount,
    int? storageUsedBytes,
    DateTime? lastActivityAt,
  }) {
    return TenantStats(
      companyId: companyId ?? this.companyId,
      membersCount: membersCount ?? this.membersCount,
      activeMembersCount: activeMembersCount ?? this.activeMembersCount,
      projectsCount: projectsCount ?? this.projectsCount,
      activeProjectsCount: activeProjectsCount ?? this.activeProjectsCount,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        companyId,
        membersCount,
        activeMembersCount,
        projectsCount,
        activeProjectsCount,
        storageUsedBytes,
        lastActivityAt,
      ];
}
