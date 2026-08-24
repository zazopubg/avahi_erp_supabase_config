import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/project_member_detail.dart';
import '../../../../domain/enums/equipment_status.dart';
import '../../../../domain/usecases/equipment/assign_equipment_usecase.dart';
import '../../../../domain/usecases/equipment/get_company_equipment_usecase.dart';
import '../../../../domain/usecases/equipment/get_equipment_by_id_usecase.dart';
import '../../../../domain/usecases/equipment/log_usage_hours_usecase.dart';
import '../../../../domain/usecases/equipment/update_equipment_status_usecase.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/projects/get_project_members_usecase.dart';
import 'equipment_state.dart';

/// نتيجة استدعاء [EquipmentCubit.logUsageHours] — تُستهلك من
/// `log_usage_screen.dart`/`equipment_details.dart` لعرض تنبيه صيانة
/// عند تجاوز العتبة، دون الحاجة لتفكيك `ResultOf` الخام في كل شاشة.
class LogUsageOutcome {
  const LogUsageOutcome({
    required this.success,
    this.equipment,
    this.maintenanceThresholdExceeded = false,
  });

  final bool success;
  final Equipment? equipment;
  final bool maintenanceThresholdExceeded;
}

/// `Cubit` ميزة `features/equipment/` (Prompt 22) — يقود كل شاشات
/// الميزة معاً (`my_equipment_screen.dart`/`log_usage_screen.dart` على
/// الهاتف، `equipment_registry.dart`/`equipment_details.dart`/
/// `maintenance_schedule.dart` على سطح المكتب) عبر [EquipmentData]
/// واحدة مجمّعة، بنفس فلسفة `DocumentsCubit`/`PunchCubit` تماماً.
///
/// ⚠️ قرار تصميم جوهري (بلا Outbox من هذه الطبقة): طبقة `data/`
/// المبنية مسبقاً لهذه الميزة (`EquipmentRepositoryImpl`، Prompt 06/10)
/// **هي نفسها** من تدير الكتابة محلياً أولاً ثم `outbox_queue` (بخلاف
/// `DocumentsCubit`/`PunchCubit` اللتين تكتبان مباشرة عبر الشبكة) —
/// انظر توثيق القرار الكامل في `EquipmentRepositoryImpl` نفسها
/// (`data/repositories_impl/equipment_repository_impl.dart`). هذا
/// الـ `Cubit` إذن لا يحتاج أي منطق Offline إضافي خاص به؛ كل استدعاء
/// [AssignEquipmentUsecase]/[LogUsageHoursUsecase]/
/// [UpdateEquipmentStatusUsecase] يعود فوراً بنسخة محدَّثة محلياً
/// (متفائلة بطبيعتها من مصدرها) تُطبَّق مباشرة على [EquipmentData.companyEquipment].
class EquipmentCubit extends Cubit<EquipmentState> {
  EquipmentCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetCompanyEquipmentUsecase getCompanyEquipmentUsecase,
    required GetEquipmentByIdUsecase getEquipmentByIdUsecase,
    required AssignEquipmentUsecase assignEquipmentUsecase,
    required LogUsageHoursUsecase logUsageHoursUsecase,
    required UpdateEquipmentStatusUsecase updateEquipmentStatusUsecase,
    required GetProjectMembersUsecase getProjectMembersUsecase,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getCompanyEquipmentUsecase = getCompanyEquipmentUsecase,
        _getEquipmentByIdUsecase = getEquipmentByIdUsecase,
        _assignEquipmentUsecase = assignEquipmentUsecase,
        _logUsageHoursUsecase = logUsageHoursUsecase,
        _updateEquipmentStatusUsecase = updateEquipmentStatusUsecase,
        _getProjectMembersUsecase = getProjectMembersUsecase,
        super(const EquipmentLoading());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetCompanyEquipmentUsecase _getCompanyEquipmentUsecase;
  final GetEquipmentByIdUsecase _getEquipmentByIdUsecase;
  final AssignEquipmentUsecase _assignEquipmentUsecase;
  final LogUsageHoursUsecase _logUsageHoursUsecase;
  final UpdateEquipmentStatusUsecase _updateEquipmentStatusUsecase;
  final GetProjectMembersUsecase _getProjectMembersUsecase;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى عند دخول `my_equipment_screen.dart` (الهاتف، نقطة
  /// الدخول الموحَّدة لمسار `RouteNames.equipment`) أو
  /// `equipment_registry.dart` (سطح المكتب) — يجلب مشاريع المستخدم ثم
  /// سجل معدات الشركة الكامل معاً (انظر توثيق القرار الكامل في
  /// [EquipmentData.companyEquipment]).
  Future<void> loadInitial(AppUser user) async {
    emit(const EquipmentLoading());

    final ResultOf<List<Project>> projectsResult = await _getMyProjectsUsecase(
      user.userId,
    );
    final List<Project> projects = projectsResult.fold(
      (Failure _) => const <Project>[],
      (List<Project> p) => p,
    );
    final Map<String, Project> projectsById = <String, Project>{
      for (final Project p in projects) p.id: p,
    };

    final ResultOf<List<Equipment>> equipmentResult =
        await _getCompanyEquipmentUsecase();

    equipmentResult.fold(
      (Failure failure) => emit(EquipmentError(failure)),
      (List<Equipment> equipment) => emit(
        EquipmentLoaded(
          EquipmentData(
            currentUser: user,
            myProjects: projects,
            projectsById: projectsById,
            companyEquipment: equipment,
          ),
        ),
      ),
    );
  }

  /// يعيد تحميل [EquipmentData.companyEquipment] فقط — سحب للتحديث
  /// في `equipment_registry.dart`/`my_equipment_screen.dart`.
  Future<void> refresh() async {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;

    emit(EquipmentLoaded(current.copyWith(isEquipmentLoading: true)));
    final ResultOf<List<Equipment>> result = await _getCompanyEquipmentUsecase();
    final List<Equipment> equipment = result.fold(
      (Failure _) => current.companyEquipment,
      (List<Equipment> e) => e,
    );
    final EquipmentData latest = state.dataOrNull ?? current;
    emit(
      EquipmentLoaded(
        latest.copyWith(
          companyEquipment: equipment,
          isEquipmentLoading: false,
        ),
      ),
    );
  }

  /// يُستدعى عند الدخول المباشر (Deep Link) لتفاصيل معدة محدَّدة دون
  /// المرور أولاً بـ [loadInitial] — بنفس نمط
  /// `DocumentsCubit.loadSingleDocument`.
  Future<void> loadSingleEquipment({
    required AppUser user,
    required String equipmentId,
  }) async {
    emit(const EquipmentLoading());

    final ResultOf<Equipment> result = await _getEquipmentByIdUsecase(
      equipmentId,
    );

    result.fold(
      (Failure failure) => emit(EquipmentError(failure)),
      (Equipment equipment) => emit(
        EquipmentLoaded(
          EquipmentData(
            currentUser: user,
            companyEquipment: <Equipment>[equipment],
            selectedEquipment: equipment,
          ),
        ),
      ),
    );
  }

  // ── تصفية (`equipment_registry.dart`) ─────────────────────────────

  void setStatusFilter(EquipmentStatus? status) {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      EquipmentLoaded(
        current.copyWith(
          statusFilter: status,
          clearStatusFilter: status == null,
        ),
      ),
    );
  }

  void setSearchQuery(String query) {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;
    emit(EquipmentLoaded(current.copyWith(searchQuery: query)));
  }

  void clearFilters() {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      EquipmentLoaded(
        current.copyWith(clearStatusFilter: true, searchQuery: ''),
      ),
    );
  }

  void selectEquipment(Equipment? equipment) {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      EquipmentLoaded(
        equipment == null
            ? current.copyWith(clearSelectedEquipment: true)
            : current.copyWith(selectedEquipment: equipment),
      ),
    );
  }

  // ── فريق مشروع للإسناد (`assign_equipment_dialog.dart`) ──────────

  /// يجلب فريق عمل [projectId] لتغذية قائمة اختيار المستخدم ضمن
  /// [AssignEquipmentDialog] — يُستدعى فقط بعد اختيار مشروع فعلياً
  /// (انظر توثيق القرار الكامل في [EquipmentData.projectMembers]).
  Future<void> loadProjectMembersForAssign(String projectId) async {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;

    emit(EquipmentLoaded(current.copyWith(isMembersLoading: true)));
    final ResultOf<List<ProjectMemberDetail>> result =
        await _getProjectMembersUsecase(projectId);
    final List<ProjectMemberDetail> members = result.fold(
      (Failure _) => const <ProjectMemberDetail>[],
      (List<ProjectMemberDetail> m) => m,
    );
    final EquipmentData latest = state.dataOrNull ?? current;
    emit(
      EquipmentLoaded(
        latest.copyWith(projectMembers: members, isMembersLoading: false),
      ),
    );
  }

  /// يمسح [EquipmentData.projectMembers] المُحمَّلة سابقاً — يُستدعى
  /// عند إغلاق [AssignEquipmentDialog] أو تغيير المشروع المختار فيه.
  void clearProjectMembers() {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      EquipmentLoaded(
        current.copyWith(
          projectMembers: const <ProjectMemberDetail>[],
        ),
      ),
    );
  }

  // ── إسناد (`assign_equipment_dialog.dart`) ────────────────────────

  /// يُسند [equipment] إلى [assignedTo]/[projectId] (أو يلغي الإسناد
  /// عند تمرير كليهما `null`) عبر [AssignEquipmentUsecase] (تتحقّق
  /// أولاً من عدم كون المعدة متقاعدة/قيد صيانة — انظر توثيقها). يُطبَّق
  /// تحديث فوري على [EquipmentData.companyEquipment] عند النجاح. يُعيد
  /// `true` عند النجاح.
  Future<bool> assignEquipment({
    required Equipment equipment,
    String? assignedTo,
    String? projectId,
  }) async {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return false;

    emit(EquipmentLoaded(current.copyWith(isAssigning: true)));

    final ResultOf<Equipment> result = await _assignEquipmentUsecase(
      equipment: equipment,
      assignedTo: assignedTo,
      projectId: projectId,
    );

    final EquipmentData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(EquipmentLoaded(latest.copyWith(isAssigning: false)));
        return false;
      },
      (Equipment updated) {
        emit(
          EquipmentLoaded(
            latest.copyWith(
              companyEquipment: _replaceEquipment(
                latest.companyEquipment,
                updated,
              ),
              selectedEquipment:
                  latest.selectedEquipment?.id == updated.id
                      ? updated
                      : latest.selectedEquipment,
              isAssigning: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── تسجيل ساعات تشغيل (`log_usage_screen.dart`) ───────────────────

  /// يسجّل [additionalHours] ساعة تشغيل إضافية على [equipment] عبر
  /// [LogUsageHoursUsecase]، ويضيف نقطة جديدة إلى
  /// [EquipmentData.usageLogByEquipmentId] (سجل الجلسة الحالية،
  /// لتغذية `usage_hours_chart.dart` — انظر توثيق القرار الكامل في
  /// `EquipmentData`). [note] اختياري لا يُحفَظ على الخادم (لا عمود
  /// مخصّص له في `public.equipment`) — يُحفَظ فقط ضمن [UsageLogEntry]
  /// المحلية نفسها لعرضه في تفاصيل السجل خلال هذه الجلسة.
  Future<LogUsageOutcome> logUsageHours({
    required Equipment equipment,
    required double additionalHours,
    String? note,
  }) async {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return const LogUsageOutcome(success: false);

    emit(EquipmentLoaded(current.copyWith(isLoggingUsage: true)));

    final ResultOf<LogUsageHoursResult> result = await _logUsageHoursUsecase(
      equipment: equipment,
      additionalHours: additionalHours,
    );

    final EquipmentData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(EquipmentLoaded(latest.copyWith(isLoggingUsage: false)));
        return const LogUsageOutcome(success: false);
      },
      (LogUsageHoursResult logResult) {
        final Equipment updated = logResult.equipment;
        final List<UsageLogEntry> existingLog =
            latest.usageLogByEquipmentId[equipment.id] ??
                <UsageLogEntry>[
                  UsageLogEntry(
                    loggedAt: equipment.updatedAt,
                    additionalHours: 0,
                    cumulativeHoursAfter: equipment.usageHours,
                  ),
                ];
        final List<UsageLogEntry> updatedLog = <UsageLogEntry>[
          ...existingLog,
          UsageLogEntry(
            loggedAt: DateTime.now(),
            additionalHours: additionalHours,
            cumulativeHoursAfter: updated.usageHours,
            note: note,
          ),
        ];

        emit(
          EquipmentLoaded(
            latest.copyWith(
              companyEquipment: _replaceEquipment(
                latest.companyEquipment,
                updated,
              ),
              selectedEquipment:
                  latest.selectedEquipment?.id == updated.id
                      ? updated
                      : latest.selectedEquipment,
              isLoggingUsage: false,
              usageLogByEquipmentId: <String, List<UsageLogEntry>>{
                ...latest.usageLogByEquipmentId,
                equipment.id: updatedLog,
              },
            ),
          ),
        );

        return LogUsageOutcome(
          success: true,
          equipment: updated,
          maintenanceThresholdExceeded:
              logResult.maintenanceThresholdExceeded,
        );
      },
    );
  }

  // ── تحديث الحالة (`maintenance_schedule.dart`/`equipment_details.dart`) ─

  /// يحدّث حالة [equipment] صراحةً (إرسالها للصيانة، إعادتها متاحة
  /// بعد إنجاز الصيانة، أو إخراجها نهائياً من الخدمة) عبر
  /// [UpdateEquipmentStatusUsecase] — انظر توثيق القرار الكامل هناك
  /// (لا تحديث فعلي لتواريخ الصيانة على الخادم في هذه الخطوة). يُعيد
  /// `true` عند النجاح.
  Future<bool> updateStatus({
    required Equipment equipment,
    required EquipmentStatus status,
  }) async {
    final EquipmentData? current = state.dataOrNull;
    if (current == null) return false;

    emit(EquipmentLoaded(current.copyWith(isUpdatingStatus: true)));

    final ResultOf<Equipment> result = await _updateEquipmentStatusUsecase(
      equipmentId: equipment.id,
      status: status,
    );

    final EquipmentData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(EquipmentLoaded(latest.copyWith(isUpdatingStatus: false)));
        return false;
      },
      (Equipment updated) {
        emit(
          EquipmentLoaded(
            latest.copyWith(
              companyEquipment: _replaceEquipment(
                latest.companyEquipment,
                updated,
              ),
              selectedEquipment:
                  latest.selectedEquipment?.id == updated.id
                      ? updated
                      : latest.selectedEquipment,
              isUpdatingStatus: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── مساعدات خاصة ─────────────────────────────────────────────────

  List<Equipment> _replaceEquipment(
    List<Equipment> source,
    Equipment updated,
  ) {
    return source
        .map((Equipment e) => e.id == updated.id ? updated : e)
        .toList(growable: false);
  }
}
