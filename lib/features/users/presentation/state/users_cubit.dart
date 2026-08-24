import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../domain/usecases/users/get_company_members_usecase.dart';
import '../../../../domain/usecases/users/invite_user_usecase.dart';
import '../../../../domain/usecases/users/update_member_role_usecase.dart';
import '../../../../domain/usecases/users/update_member_status_usecase.dart';
import 'users_state.dart';

/// `Cubit` ميزة `features/users/` (Prompt 26) — يقود شاشة
/// `users_list.dart` الوحيدة وكل ما تُظهره من لوحات فرعية
/// (`user_details.dart`/`user_roles_edit.dart`/`invite_user.dart`) عبر
/// [UsersData] واحدة مجمّعة، بنفس فلسفة `LeaveCubit`/`EquipmentCubit`
/// تماماً.
///
/// ⚠️ قرار تصميم (بلا اشتراك لحظي/Realtime، وبلا Outbox): بنفس منطق
/// `LeaveCubit` الموثَّق هناك — تغييرات عضوية/دور نادرة نسبياً، ولا
/// معنى فعلياً لتنفيذها أوفلاين أولاً (إجراء إداري يفترض اتصالاً
/// دائماً، انظر توثيق القرار في `UserRepositoryImpl`). [refresh] يدوي
/// فقط.
class UsersCubit extends Cubit<UsersState> {
  UsersCubit({
    required GetCompanyMembersUsecase getCompanyMembersUsecase,
    required UpdateMemberRoleUsecase updateMemberRoleUsecase,
    required UpdateMemberStatusUsecase updateMemberStatusUsecase,
    required InviteUserUsecase inviteUserUsecase,
  })  : _getCompanyMembersUsecase = getCompanyMembersUsecase,
        _updateMemberRoleUsecase = updateMemberRoleUsecase,
        _updateMemberStatusUsecase = updateMemberStatusUsecase,
        _inviteUserUsecase = inviteUserUsecase,
        super(const UsersLoading());

  final GetCompanyMembersUsecase _getCompanyMembersUsecase;
  final UpdateMemberRoleUsecase _updateMemberRoleUsecase;
  final UpdateMemberStatusUsecase _updateMemberStatusUsecase;
  final InviteUserUsecase _inviteUserUsecase;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى عند دخول `users_list.dart` (نقطة الدخول الوحيدة لمسار
  /// `RouteNames.users`).
  Future<void> loadInitial(AppUser user) async {
    emit(const UsersLoading());

    final ResultOf<List<AppUser>> result =
        await _getCompanyMembersUsecase(user.companyId);

    result.fold(
      (Failure failure) => emit(UsersError(failure)),
      (List<AppUser> members) => emit(
        UsersLoaded(UsersData(currentUser: user, members: members)),
      ),
    );
  }

  Future<void> refresh() async {
    final UsersData? current = state.dataOrNull;
    if (current == null) return;

    emit(UsersLoaded(current.copyWith(isRefreshing: true)));

    final ResultOf<List<AppUser>> result =
        await _getCompanyMembersUsecase(current.currentUser.companyId);

    final UsersData latest = state.dataOrNull ?? current;
    result.fold(
      (Failure _) => emit(UsersLoaded(latest.copyWith(isRefreshing: false))),
      (List<AppUser> members) => emit(
        UsersLoaded(
          latest.copyWith(members: members, isRefreshing: false),
        ),
      ),
    );
  }

  // ── تصفية/بحث (`users_list.dart`) ─────────────────────────────────

  void setSearchQuery(String query) {
    final UsersData? current = state.dataOrNull;
    if (current == null) return;
    emit(UsersLoaded(current.copyWith(searchQuery: query)));
  }

  void setRoleFilter(UserRole? role) {
    final UsersData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      UsersLoaded(
        role == null
            ? current.copyWith(clearRoleFilter: true)
            : current.copyWith(roleFilter: role),
      ),
    );
  }

  /// `null` = كل الحالات، `true` = نشطون فقط، `false` = معطَّلون فقط.
  void setActiveOnlyFilter(bool? activeOnly) {
    final UsersData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      UsersLoaded(
        activeOnly == null
            ? current.copyWith(clearActiveOnlyFilter: true)
            : current.copyWith(activeOnly: activeOnly),
      ),
    );
  }

  void clearFilters() {
    final UsersData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      UsersLoaded(
        current.copyWith(
          searchQuery: '',
          clearRoleFilter: true,
          clearActiveOnlyFilter: true,
        ),
      ),
    );
  }

  // ── تحديد عضو للعرض (`user_details.dart`) ─────────────────────────

  void selectMember(AppUser? member) {
    final UsersData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      UsersLoaded(
        member == null
            ? current.copyWith(clearSelectedMember: true)
            : current.copyWith(selectedMemberId: member.id),
      ),
    );
  }

  // ── تعديل دور (`user_roles_edit.dart`) ─────────────────────────────

  /// يحدّث دور [member] إلى [role]. يرفض تعديل دور [UsersData.currentUser]
  /// نفسه دفاعياً (لتفادي تعطيل المستخدم الحالي نفسه من صلاحياته
  /// الإدارية بالخطأ) — نفس القيد المعروض بتعطيل الزر في الواجهة
  /// (`user_roles_edit.dart`)، لكن مُفروض هنا أيضاً كخط دفاع ثانٍ.
  Future<bool> updateMemberRole({
    required AppUser member,
    required UserRole role,
  }) async {
    final UsersData? current = state.dataOrNull;
    if (current == null) return false;
    if (member.id == current.currentUser.id) return false;

    emit(UsersLoaded(current.copyWith(isSavingRole: true)));

    final ResultOf<AppUser> result = await _updateMemberRoleUsecase(
      membershipId: member.id,
      role: role,
    );

    final UsersData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(UsersLoaded(latest.copyWith(isSavingRole: false)));
        return false;
      },
      (AppUser updated) {
        emit(
          UsersLoaded(
            latest.copyWith(
              members: _replaceMember(latest.members, updated),
              isSavingRole: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── تفعيل/تعطيل (`user_details.dart`) ───────────────────────────────

  /// يفعّل/يعطّل [member]. يرفض تعطيل [UsersData.currentUser] نفسه
  /// دفاعياً (بنفس منطق [updateMemberRole] أعلاه — لا يجوز لمستخدم أن
  /// يقفل وصوله الخاص عن طريق الخطأ).
  Future<bool> updateMemberStatus({
    required AppUser member,
    required bool isActive,
  }) async {
    final UsersData? current = state.dataOrNull;
    if (current == null) return false;
    if (member.id == current.currentUser.id) return false;

    emit(UsersLoaded(current.copyWith(isSavingStatus: true)));

    final ResultOf<AppUser> result = await _updateMemberStatusUsecase(
      membershipId: member.id,
      isActive: isActive,
    );

    final UsersData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure _) {
        emit(UsersLoaded(latest.copyWith(isSavingStatus: false)));
        return false;
      },
      (AppUser updated) {
        emit(
          UsersLoaded(
            latest.copyWith(
              members: _replaceMember(latest.members, updated),
              isSavingStatus: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  // ── دعوة عضو جديد (`invite_user.dart`) ──────────────────────────────

  Future<AppUser?> inviteUser({
    required String email,
    required String fullName,
    required UserRole role,
    String? jobTitle,
    String? phone,
  }) async {
    final UsersData? current = state.dataOrNull;
    if (current == null) return null;

    emit(
      UsersLoaded(
        current.copyWith(isInviting: true, clearInviteErrorMessage: true),
      ),
    );

    final ResultOf<AppUser> result = await _inviteUserUsecase(
      companyId: current.currentUser.companyId,
      email: email,
      fullName: fullName,
      role: role,
      jobTitle: jobTitle,
      phone: phone,
    );

    final UsersData latest = state.dataOrNull ?? current;
    return result.fold(
      (Failure failure) {
        emit(
          UsersLoaded(
            latest.copyWith(
              isInviting: false,
              inviteErrorMessage: failure.message,
            ),
          ),
        );
        return null;
      },
      (AppUser invited) {
        emit(
          UsersLoaded(
            latest.copyWith(
              members: <AppUser>[invited, ...latest.members],
              isInviting: false,
              clearInviteErrorMessage: true,
            ),
          ),
        );
        return invited;
      },
    );
  }

  List<AppUser> _replaceMember(List<AppUser> members, AppUser updated) {
    return members
        .map((AppUser m) => m.id == updated.id ? updated : m)
        .toList(growable: false);
  }
}
