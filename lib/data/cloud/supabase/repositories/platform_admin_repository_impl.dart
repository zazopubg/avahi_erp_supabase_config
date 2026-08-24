import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/audit_log.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/entities/error_log_entry.dart';
import '../../../../domain/entities/platform_usage_snapshot.dart';
import '../../../../domain/entities/subscription_plan.dart';
import '../../../../domain/entities/tenant_stats.dart';
import '../../../../domain/entities/tenant_subscription.dart';
import '../../../../domain/repositories/i_platform_admin_repository.dart';
import '../../../dto/audit_log_dto.dart';
import '../../../dto/company_dto.dart';
import '../supabase_client_provider.dart';
import '../supabase_error_mapper.dart';

/// تنفيذ [IPlatformAdminRepository] — يجمع بين:
/// 1) استعلامات Postgrest حقيقية مباشرة (companies/audit_logs/إحصاءات
///    company_members/projects/documents/photos)، معتمداً بالكامل على
///    سياسات RLS الموجودة فعلياً (`016_rls_policies.sql`،
///    `auth.is_platform_owner()`) لإتاحة القراءة العابرة للمستأجرين —
///    بلا أي فحص دور إضافي هنا (بنفس فلسفة كل *RepositoryImpl* أخرى:
///    الفرض الملزم في RLS، لا في طبقة `data/`).
/// 2) ثلاث Edge Functions بصلاحية `service_role` (`create-company`/
///    `soft-delete-tenant`/`export-tenant-data` 🆕) للعمليات التي
///    تتجاوز RLS عمداً (إنشاء شركة، تعطيلها، توليد رابط تصدير موقّع).
/// 3) بيانات مولَّدة حتمياً (Deterministic Mock) للأقسام الأربعة التي
///    لا مصدر بيانات حقيقياً لها بعد (خطط/فوترة/استخدام/أخطاء) — انظر
///    توثيق القرار الكامل في كل كيان مقابل
///    (`SubscriptionPlan`/`TenantSubscription`/`PlatformUsageSnapshot`/
///    `ErrorLogEntry`)، وتُبنى دائماً فوق شركات حقيقية مسحوبة من
///    [getAllCompanies] (لا معرّفات وهمية بالكامل).
/// 🆕 (Prompt 28)
class PlatformAdminRepositoryImpl implements IPlatformAdminRepository {
  PlatformAdminRepositoryImpl({sb.SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  final sb.SupabaseClient _client;

  // ── الشركات/المستأجرون ──────────────────────────────────────────

  @override
  Future<ResultOf<List<Company>>> getAllCompanies() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(ApiConstants.tableCompanies)
          .select()
          .order('created_at', ascending: false);

      return Right<Failure, List<Company>>(
        rows
            .map(
              (Map<String, dynamic> row) => CompanyDto.fromJson(row).toEntity(),
            )
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<Company>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<TenantStats>> getTenantStats(String companyId) async {
    try {
      final List<Map<String, dynamic>> members = await _client
          .from(ApiConstants.tableCompanyMembers)
          .select('is_active, updated_at')
          .eq('company_id', companyId);

      final List<Map<String, dynamic>> projects = await _client
          .from(ApiConstants.tableProjects)
          .select('status')
          .eq('company_id', companyId);

      final List<Map<String, dynamic>> documents = await _client
          .from(ApiConstants.tableDocuments)
          .select('file_size_bytes')
          .eq('company_id', companyId);

      final List<Map<String, dynamic>> photos = await _client
          .from(ApiConstants.tablePhotos)
          .select('file_size_bytes')
          .eq('company_id', companyId);

      final int activeMembersCount =
          members.where((Map<String, dynamic> m) => m['is_active'] == true).length;

      final int activeProjectsCount = projects
          .where((Map<String, dynamic> p) => p['status'] == 'active')
          .length;

      final int storageUsedBytes = <Map<String, dynamic>>[...documents, ...photos]
          .fold<int>(
        0,
        (int sum, Map<String, dynamic> row) =>
            sum + ((row['file_size_bytes'] as num?)?.toInt() ?? 0),
      );

      DateTime? lastActivityAt;
      for (final Map<String, dynamic> member in members) {
        final String? raw = member['updated_at'] as String?;
        if (raw == null) continue;
        final DateTime parsed = DateTime.parse(raw);
        if (lastActivityAt == null || parsed.isAfter(lastActivityAt)) {
          lastActivityAt = parsed;
        }
      }

      return Right<Failure, TenantStats>(
        TenantStats(
          companyId: companyId,
          membersCount: members.length,
          activeMembersCount: activeMembersCount,
          projectsCount: projects.length,
          activeProjectsCount: activeProjectsCount,
          storageUsedBytes: storageUsedBytes,
          lastActivityAt: lastActivityAt,
        ),
      );
    } catch (error, stackTrace) {
      return Left<Failure, TenantStats>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Company>> createTenant({
    required String name,
    required String slug,
    String? nameAr,
    String? timezone,
    String? address,
    String? phone,
    String? logoUrl,
    String? initialAdminUserId,
    String? initialAdminFullName,
  }) async {
    try {
      final sb.FunctionResponse response = await _client.functions.invoke(
        ApiConstants.fnCreateCompany,
        body: <String, dynamic>{
          'name': name,
          'slug': slug,
          if (nameAr != null) 'name_ar': nameAr,
          if (timezone != null) 'timezone': timezone,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (logoUrl != null) 'logo_url': logoUrl,
          if (initialAdminUserId != null)
            'initial_admin_user_id': initialAdminUserId,
          if (initialAdminFullName != null)
            'initial_admin_full_name': initialAdminFullName,
        },
      );

      final Map<String, dynamic> envelope = _parseEnvelope(response);
      final Map<String, dynamic> payload =
          (envelope['data'] as Map).cast<String, dynamic>();
      final Map<String, dynamic> companyJson =
          (payload['company'] as Map).cast<String, dynamic>();
      return Right<Failure, Company>(CompanyDto.fromJson(companyJson).toEntity());
    } on _EdgeFunctionFailure catch (failure) {
      return Left<Failure, Company>(failure.toFailure('tenants'));
    } catch (error, stackTrace) {
      return Left<Failure, Company>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<Company>> softDeleteTenant({
    required String companyId,
    String? reason,
  }) async {
    try {
      final sb.FunctionResponse response = await _client.functions.invoke(
        ApiConstants.fnSoftDeleteTenant,
        body: <String, dynamic>{
          'company_id': companyId,
          if (reason != null) 'reason': reason,
        },
      );

      final Map<String, dynamic> envelope = _parseEnvelope(response);
      final Map<String, dynamic> payload =
          (envelope['data'] as Map).cast<String, dynamic>();
      final Map<String, dynamic> companyJson =
          (payload['company'] as Map).cast<String, dynamic>();
      return Right<Failure, Company>(CompanyDto.fromJson(companyJson).toEntity());
    } on _EdgeFunctionFailure catch (failure) {
      return Left<Failure, Company>(failure.toFailure('tenants'));
    } catch (error, stackTrace) {
      return Left<Failure, Company>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<String>> exportTenantData(String companyId) async {
    try {
      final sb.FunctionResponse response = await _client.functions.invoke(
        ApiConstants.fnExportTenantData,
        body: <String, dynamic>{'company_id': companyId},
      );

      final Map<String, dynamic> envelope = _parseEnvelope(response);
      final Map<String, dynamic> payload =
          (envelope['data'] as Map).cast<String, dynamic>();
      final String? downloadUrl = payload['download_url'] as String?;
      if (downloadUrl == null) {
        return const Left<Failure, String>(
          NetworkFailure(
            message: 'استجابة غير متوقعة من دالة تصدير بيانات المستأجر.',
            code: 'platform_admin.invalid_export_response',
          ),
        );
      }
      return Right<Failure, String>(downloadUrl);
    } on _EdgeFunctionFailure catch (failure) {
      return Left<Failure, String>(failure.toFailure('platform_admin'));
    } catch (error, stackTrace) {
      return Left<Failure, String>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  // ── سجل التدقيق ─────────────────────────────────────────────────

  @override
  Future<ResultOf<List<AuditLog>>> getAllAuditLogs({
    String? companyId,
    String? action,
    String? tableName,
    int limit = 200,
  }) async {
    try {
      sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
          _client.from(ApiConstants.tableAuditLogs).select();

      if (companyId != null) query = query.eq('company_id', companyId);
      if (action != null) query = query.eq('action', action);
      if (tableName != null) query = query.eq('table_name', tableName);

      final List<Map<String, dynamic>> rows = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return Right<Failure, List<AuditLog>>(
        rows
            .map(
              (Map<String, dynamic> row) => AuditLogDto.fromJson(row).toEntity(),
            )
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Left<Failure, List<AuditLog>>(
        Failure.fromException(SupabaseErrorMapper.map(error, stackTrace)),
      );
    }
  }

  // ── خطط الاشتراك/الفوترة (مولَّدة — انظر توثيق القرار في الكيانات) ──

  @override
  Future<ResultOf<List<SubscriptionPlan>>> getSubscriptionPlans() async {
    return const Right<Failure, List<SubscriptionPlan>>(_staticPlans);
  }

  @override
  Future<ResultOf<List<TenantSubscription>>> getTenantSubscriptions() async {
    final ResultOf<List<Company>> companiesResult = await getAllCompanies();
    return companiesResult.map(
      (List<Company> companies) => <TenantSubscription>[
        for (int i = 0; i < companies.length; i++)
          _buildMockSubscription(companies[i], index: i),
      ],
    );
  }

  @override
  Future<ResultOf<TenantSubscription>> updateTenantPlan({
    required String companyId,
    required String newPlanId,
  }) async {
    // ⚠️ لا جدول `tenant_subscriptions` حقيقياً بعد (انظر توثيق القرار
    // الكامل في `TenantSubscription`) — هذا التعديل يبقى محلياً على
    // مستوى العرض فقط حالياً (`PlatformAdminCubit` يُحدّث حالته بالقيمة
    // المُعادة هنا مباشرة دون أي كتابة فعلية لقاعدة بيانات)، بانتظار
    // Prompt مستقبلي مخصّص لنظام الفوترة الفعلي.
    final SubscriptionPlan plan = _staticPlans.firstWhere(
      (SubscriptionPlan p) => p.id == newPlanId,
      orElse: () => _staticPlans.first,
    );
    return Right<Failure, TenantSubscription>(
      TenantSubscription(
        companyId: companyId,
        planId: plan.id,
        status: TenantSubscriptionStatus.active,
        startedAt: DateTime.now(),
        currentPeriodEndsAt: DateTime.now().add(const Duration(days: 30)),
        mrrUsd: plan.monthlyPriceUsd,
      ),
    );
  }

  // ── مراقبة الاستخدام/الأخطاء (مولَّدة — انظر توثيق القرار في الكيانات) ──

  @override
  Future<ResultOf<PlatformUsageSnapshot>> getPlatformUsageSnapshot() async {
    final ResultOf<List<Company>> companiesResult = await getAllCompanies();
    return companiesResult.map(_buildMockUsageSnapshot);
  }

  @override
  Future<ResultOf<List<ErrorLogEntry>>> getRecentErrorLogs({
    int limit = 50,
  }) async {
    final ResultOf<List<Company>> companiesResult = await getAllCompanies();
    return companiesResult.map(
      (List<Company> companies) => _buildMockErrorLogs(companies, limit: limit),
    );
  }

  // ── دوال توليد البيانات التجريبية الحتمية (Deterministic Mock) ────
  // ⚠️ لا Random() في أي دالة هنا عمداً — القيم مشتقة رياضياً من عدد/
  // ترتيب الشركات الحقيقية فقط، بحيث تبقى نتائج [getAllCompanies]
  // ثابتة (Stable) بين استدعاءين متتاليين (مهم لـ `PlatformAdminCubit.refresh`
  // كي لا تتقافز الأرقام المعروضة بلا سبب حقيقي عند كل تحديث).

  static const List<SubscriptionPlan> _staticPlans = <SubscriptionPlan>[
    SubscriptionPlan(
      id: 'starter',
      name: 'Starter',
      nameAr: 'الأساسية',
      monthlyPriceUsd: 49,
      maxUsers: 15,
      maxProjects: 3,
      maxStorageGb: 10,
      features: <String>[
        'إدارة حضور وتقارير ميدانية أساسية',
        'حتى 3 مشاريع نشطة',
        'دعم عبر البريد الإلكتروني',
      ],
    ),
    SubscriptionPlan(
      id: 'growth',
      name: 'Growth',
      nameAr: 'النمو',
      monthlyPriceUsd: 149,
      maxUsers: 60,
      maxProjects: 15,
      maxStorageGb: 100,
      features: <String>[
        'كل ميزات الخطة الأساسية',
        'تحليلات تنفيذية ولوحات متقدمة',
        'قوائم ملاحظات ومعدات غير محدودة',
        'دعم أولوية عبر الدردشة',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'enterprise',
      name: 'Enterprise',
      nameAr: 'المؤسسات',
      monthlyPriceUsd: 399,
      maxUsers: -1,
      maxProjects: -1,
      maxStorageGb: -1,
      features: <String>[
        'مستخدمون ومشاريع وتخزين غير محدود',
        'مدير حساب مخصّص',
        'اتفاقية مستوى خدمة (SLA) مخصّصة',
        'تكامل مخصّص عند الطلب',
      ],
    ),
  ];

  TenantSubscription _buildMockSubscription(
    Company company, {
    required int index,
  }) {
    final SubscriptionPlan plan = _staticPlans[index % _staticPlans.length];
    final TenantSubscriptionStatus status = !company.isActive
        ? TenantSubscriptionStatus.cancelled
        : switch (index % 5) {
            0 => TenantSubscriptionStatus.trial,
            4 => TenantSubscriptionStatus.pastDue,
            _ => TenantSubscriptionStatus.active,
          };
    return TenantSubscription(
      companyId: company.id,
      planId: plan.id,
      status: status,
      startedAt: company.createdAt,
      currentPeriodEndsAt: DateTime.now().add(Duration(days: 30 - (index % 30))),
      mrrUsd: status.isCancelled ? 0 : plan.monthlyPriceUsd,
    );
  }

  PlatformUsageSnapshot _buildMockUsageSnapshot(List<Company> companies) {
    final int totalTenants = companies.length;
    final int activeTenants =
        companies.where((Company c) => c.isActive).length;
    // تقدير مستخدمين تقريبي (12 مستخدماً بالمعدل لكل مستأجر نشط) —
    // بديل حتمي بانتظار استعلام `count(company_members)` عابر لكل
    // الشركات دفعة واحدة (غير ضروري الآن لعرض تقديري فقط).
    final int totalUsers = activeTenants * 12;

    final DateTime today = DateTime.now();
    final List<PlatformUsageTrendPoint> trend = <PlatformUsageTrendPoint>[
      for (int i = 13; i >= 0; i--)
        PlatformUsageTrendPoint(
          date: today.subtract(Duration(days: i)),
          activeTenantsCount:
              (activeTenants - (i % 4)).clamp(0, activeTenants),
        ),
    ];

    return PlatformUsageSnapshot(
      capturedAt: today,
      totalTenants: totalTenants,
      activeTenants: activeTenants,
      totalUsers: totalUsers,
      activeUsersToday: (totalUsers * 0.35).round(),
      totalStorageGb: activeTenants * 2.4,
      apiRequestsToday: totalUsers * 47,
      avgResponseTimeMs: 180,
      errorRatePercent: 0.42,
      dailyActiveTenantsTrend: trend,
    );
  }

  List<ErrorLogEntry> _buildMockErrorLogs(
    List<Company> companies, {
    required int limit,
  }) {
    if (companies.isEmpty) return const <ErrorLogEntry>[];

    const List<(ErrorLogSeverity, String, String)> templates =
        <(ErrorLogSeverity, String, String)>[
      (
        ErrorLogSeverity.warning,
        'client:sync-engine',
        'إعادة محاولة مزامنة صف واحد بعد فشل شبكة مؤقت.',
      ),
      (
        ErrorLogSeverity.error,
        'edge-function:invite-user',
        'فشل إرسال دعوة عضو جديد بسبب بريد إلكتروني مكرر.',
      ),
      (
        ErrorLogSeverity.info,
        'client:outbox-processor',
        'تعليق معالجة الطابور مؤقتاً بسبب انقطاع اتصال.',
      ),
      (
        ErrorLogSeverity.critical,
        'db:connection-pool',
        'استنفاد مؤقت لمجمّع اتصالات قاعدة البيانات.',
      ),
      (
        ErrorLogSeverity.error,
        'edge-function:attendance-guard',
        'رفض تسجيل حضور خارج نطاق الجيوفنسينغ المسموح.',
      ),
    ];

    final DateTime now = DateTime.now();
    return <ErrorLogEntry>[
      for (int i = 0; i < limit && i < companies.length * templates.length; i++)
        () {
          final (ErrorLogSeverity severity, String source, String message) =
              templates[i % templates.length];
          final Company company = companies[i % companies.length];
          return ErrorLogEntry(
            id: 'mock-log-$i',
            severity: severity,
            source: source,
            message: message,
            occurredAt: now.subtract(Duration(minutes: i * 37)),
            isResolved: i % 3 == 0,
            companyId: company.id,
          );
        }(),
    ];
  }

  // ── تفكيك استجابة Edge Function الموحّدة ───────────────────────────

  Map<String, dynamic> _parseEnvelope(sb.FunctionResponse response) {
    final Object? data = response.data;
    if (data is! Map) {
      throw const _EdgeFunctionFailure(
        message: 'استجابة غير متوقعة من الخادم.',
        code: 'invalid_response',
      );
    }
    final Map<String, dynamic> envelope = data.cast<String, dynamic>();
    if (envelope['success'] != true) {
      final Map<String, dynamic>? error =
          (envelope['error'] as Map?)?.cast<String, dynamic>();
      throw _EdgeFunctionFailure(
        message: error?['message']?.toString() ?? 'فشل تنفيذ الإجراء.',
        code: error?['code']?.toString() ?? 'unknown',
      );
    }
    return envelope;
  }
}

/// استثناء داخلي خاص لتبسيط تحويل استجابة `{success:false, error:{...}}`
/// إلى [Failure] موحّد دون تكرار نفس منطق الفكّ في كل دالة Edge
/// Function ثلاث مرات — يبقى داخلياً بالكامل (غير مُصدَّر) ولا يتسرّب
/// أبداً خارج هذا الملف.
class _EdgeFunctionFailure implements Exception {
  const _EdgeFunctionFailure({required this.message, required this.code});

  final String message;
  final String code;

  Failure toFailure(String domain) {
    return NetworkFailure(message: message, code: '$domain.$code');
  }
}
