import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/project_member_detail.dart';
import '../../../../domain/enums/equipment_status.dart';

/// نقطة بيانات محلية واحدة (Session-only) لسجل ساعات تشغيل مُسجَّل —
/// انظر توثيق القرار الكامل في [EquipmentData.usageLogByEquipmentId].
class UsageLogEntry {
  const UsageLogEntry({
    required this.loggedAt,
    required this.additionalHours,
    required this.cumulativeHoursAfter,
    this.note,
  });

  final DateTime loggedAt;
  final double additionalHours;
  final double cumulativeHoursAfter;
  final String? note;
}

/// حالة `EquipmentCubit` الكاملة — Union Type مكتوب يدوياً، بنفس نمط
/// `DocumentsState`/`PunchState` تماماً (بلا `freezed`، ثلاث حالات
/// فقط: `EquipmentLoading` / `EquipmentLoaded` / `EquipmentError`).
sealed class EquipmentState {
  const EquipmentState();

  T when<T>({
    required T Function() loading,
    required T Function(EquipmentData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final EquipmentState state = this;
    return switch (state) {
      EquipmentLoading() => loading(),
      EquipmentLoaded(:final data) => loaded(data),
      EquipmentError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(EquipmentData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [EquipmentData] الحالية إن كانت الحالة [EquipmentLoaded]، أو
  /// `null` — مختصر مفيد للشاشات، بنفس نمط `DocumentsState.dataOrNull`.
  EquipmentData? get dataOrNull => maybeWhen<EquipmentData?>(
        orElse: () => null,
        loaded: (EquipmentData d) => d,
      );
}

/// جارٍ التحميل الأولي (مشاريع المستخدم + سجل معدات الشركة الكامل).
final class EquipmentLoading extends EquipmentState {
  const EquipmentLoading();
}

/// جاهزة لعرض كل شاشات الميزة (`my_equipment_screen.dart` على
/// الهاتف، `equipment_registry.dart`/`equipment_details.dart`/
/// `maintenance_schedule.dart` على سطح المكتب) — الفرق بينها بصري
/// بحت حسب `ShellMode`، بنفس فلسفة `DocumentsCubit`/`PunchCubit`.
final class EquipmentLoaded extends EquipmentState {
  const EquipmentLoaded(this.data);

  final EquipmentData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً — يعتمد `Retry` في الشاشة
/// لإعادة `EquipmentCubit.loadInitial`.
final class EquipmentError extends EquipmentState {
  const EquipmentError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة المعدات المجمّعة — يحملها [EquipmentLoaded] وحدها.
class EquipmentData {
  const EquipmentData({
    required this.currentUser,
    this.myProjects = const <Project>[],
    this.projectsById = const <String, Project>{},
    this.companyEquipment = const <Equipment>[],
    this.isEquipmentLoading = false,
    this.statusFilter,
    this.searchQuery = '',
    this.selectedEquipment,
    this.isAssigning = false,
    this.isLoggingUsage = false,
    this.isUpdatingStatus = false,
    this.projectMembers = const <ProjectMemberDetail>[],
    this.isMembersLoading = false,
    this.usageLogByEquipmentId = const <String, List<UsageLogEntry>>{},
  });

  final AppUser currentUser;

  /// كل مشاريع المستخدم — تغذّي اختيار "المشروع المُسنَد إليه" ضمن
  /// [AssignEquipmentDialog] (`assign_equipment_dialog.dart`) وفلتر
  /// المشروع الاختياري في `equipment_registry.dart`.
  final List<Project> myProjects;
  final Map<String, Project> projectsById;

  /// سجل معدات الشركة **الكامل** — `getCompanyEquipment` لا تستقبل
  /// `assignedTo` (انظر `i_equipment_repository.dart`)، لذا هذه
  /// القائمة الواحدة أساس كل من `equipment_registry.dart` (سطح
  /// المكتب، بلا فلترة إضافية) و`my_equipment_screen.dart` (الهاتف،
  /// عبر [myEquipment] — تصفية جانب العميل حسب
  /// `Equipment.assignedTo == currentUser.userId`) — بنفس منطق
  /// تصفية `PhotosData`/`TasksData` جانب العميل عند غياب استعلام
  /// خادم مخصّص لكل حالة استخدام.
  final List<Equipment> companyEquipment;
  final bool isEquipmentLoading;

  // ── تصفية (سطح المكتب: `equipment_registry.dart`) ────────────────
  final EquipmentStatus? statusFilter;
  final String searchQuery;

  /// المعدة المختارة حالياً لعرض تفاصيلها — `equipment_details.dart`
  /// (لوحة جانبية مضمّنة ضمن `equipment_registry.dart`، بنفس نمط
  /// `DocumentsData.selectedDocument`/`DocumentViewerPanel`).
  final Equipment? selectedEquipment;

  /// عملية إسناد جارية حالياً — `assign_equipment_dialog.dart`.
  final bool isAssigning;

  /// عملية تسجيل ساعات تشغيل جارية حالياً — `log_usage_screen.dart`.
  final bool isLoggingUsage;

  /// عملية تحديث حالة جارية حالياً — `maintenance_schedule.dart`.
  final bool isUpdatingStatus;

  /// فريق عمل المشروع المختار حالياً ضمن [AssignEquipmentDialog] —
  /// يُحمَّل كسولاً عبر [EquipmentCubit.loadProjectMembersForAssign]
  /// فقط بعد اختيار مشروع فعلياً (تجنّباً لاستدعاءات شبكة غير
  /// ضرورية عند فتح الحوار بلا اختيار مشروع بعد).
  final List<ProjectMemberDetail> projectMembers;
  final bool isMembersLoading;

  /// ⚠️ قرار تصميم مهم (سجل استخدام محلي بحت — Session-only): طبقة
  /// `data/` المبنية مسبقاً لهذه الميزة (`IEquipmentRepository`،
  /// Prompt 06/10) لا تملك أي جدول/استعلام "سجل جلسات استخدام" مفصّل
  /// — فقط [Equipment.usageHours] التراكمية نفسها (انظر
  /// `012_create_equipment.sql`). لذا [usageLogByEquipmentId] هنا
  /// خريطة **محلية بحتة** (لا تُحفَظ ولا تُزامَن) تتجمّع فقط من
  /// استدعاءات [EquipmentCubit.logUsageHours] ضمن نفس جلسة التطبيق
  /// الحالية — أساس `usage_hours_chart.dart` (يعرض رسماً بيانياً
  /// تراكمياً لما سُجِّل *في هذه الجلسة* فقط، مع نقطة ابتداء واحدة
  /// تمثّل [Equipment.usageHours] الحالية عند التحميل). توسيع هذا
  /// لسجل دائم يتطلب أولاً توسيع طبقة `data/` (خارج نطاق Prompt 22
  /// هذا) — بنفس منطق قيود Offline الموثَّقة في `PunchCubit`.
  final Map<String, List<UsageLogEntry>> usageLogByEquipmentId;

  /// معدات المستخدم الحالي المُسندة إليه فقط — أساس
  /// `my_equipment_screen.dart` (الهاتف)، انظر توثيق القرار الكامل
  /// أعلى [companyEquipment].
  List<Equipment> get myEquipment => companyEquipment
      .where((Equipment e) => e.assignedTo == currentUser.userId)
      .toList(growable: false);

  bool get hasActiveFilters =>
      statusFilter != null || searchQuery.trim().isNotEmpty;

  /// [companyEquipment] بعد تطبيق فلاتر الحالة/البحث الحالية —
  /// `equipment_registry.dart`.
  List<Equipment> get filteredEquipment {
    Iterable<Equipment> result = companyEquipment;

    if (statusFilter != null) {
      result = result.where((Equipment e) => e.status == statusFilter);
    }
    if (searchQuery.trim().isNotEmpty) {
      final String query = searchQuery.trim().toLowerCase();
      result = result.where((Equipment e) {
        final bool nameMatch = e.name.toLowerCase().contains(query);
        final bool nameArMatch =
            e.nameAr?.toLowerCase().contains(query) ?? false;
        final bool typeMatch = e.type.toLowerCase().contains(query);
        final bool serialMatch =
            e.serialNumber?.toLowerCase().contains(query) ?? false;
        return nameMatch || nameArMatch || typeMatch || serialMatch;
      });
    }

    return result.toList(growable: false)
      ..sort((Equipment a, Equipment b) => a.name.compareTo(b.name));
  }

  /// معدات مستحقة للصيانة أو متجاوزة موعدها — أساس
  /// `maintenance_schedule.dart`. معدة "مستحقة" إن كانت
  /// [Equipment.nextMaintenanceDue] محدَّدة وقاربت خلال 14 يوماً أو
  /// انقضت فعلاً، أو تجاوزت ساعات تشغيلها منذ آخر صيانة العتبة
  /// الافتراضية ([LogUsageHoursUsecase.defaultMaintenanceThresholdHours])
  /// دون تاريخ صيانة مسجَّل أصلاً.
  List<Equipment> get maintenanceDueEquipment {
    final DateTime now = DateTime.now();
    final DateTime soonThreshold = now.add(const Duration(days: 14));
    return companyEquipment.where((Equipment e) {
      if (e.status.isRetired) return false;
      if (e.nextMaintenanceDue != null) {
        return e.nextMaintenanceDue!.isBefore(soonThreshold);
      }
      return false;
    }).toList(growable: false)
      ..sort(
        (Equipment a, Equipment b) => a.nextMaintenanceDue!.compareTo(
          b.nextMaintenanceDue!,
        ),
      );
  }

  /// من ضمن [maintenanceDueEquipment]، المعدات المتجاوزة موعدها
  /// فعلياً (`nextMaintenanceDue` في الماضي) — شارة "متأخرة" حمراء في
  /// `maintenance_schedule.dart`.
  bool isOverdue(Equipment equipment) {
    final DateTime? due = equipment.nextMaintenanceDue;
    return due != null && due.isBefore(DateTime.now());
  }

  EquipmentData copyWith({
    AppUser? currentUser,
    List<Project>? myProjects,
    Map<String, Project>? projectsById,
    List<Equipment>? companyEquipment,
    bool? isEquipmentLoading,
    EquipmentStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    Equipment? selectedEquipment,
    bool clearSelectedEquipment = false,
    bool? isAssigning,
    bool? isLoggingUsage,
    bool? isUpdatingStatus,
    List<ProjectMemberDetail>? projectMembers,
    bool? isMembersLoading,
    Map<String, List<UsageLogEntry>>? usageLogByEquipmentId,
  }) {
    return EquipmentData(
      currentUser: currentUser ?? this.currentUser,
      myProjects: myProjects ?? this.myProjects,
      projectsById: projectsById ?? this.projectsById,
      companyEquipment: companyEquipment ?? this.companyEquipment,
      isEquipmentLoading: isEquipmentLoading ?? this.isEquipmentLoading,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEquipment: clearSelectedEquipment
          ? null
          : (selectedEquipment ?? this.selectedEquipment),
      isAssigning: isAssigning ?? this.isAssigning,
      isLoggingUsage: isLoggingUsage ?? this.isLoggingUsage,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      projectMembers: projectMembers ?? this.projectMembers,
      isMembersLoading: isMembersLoading ?? this.isMembersLoading,
      usageLogByEquipmentId:
          usageLogByEquipmentId ?? this.usageLogByEquipmentId,
    );
  }
}
