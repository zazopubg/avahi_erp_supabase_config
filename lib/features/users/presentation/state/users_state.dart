import '../../../../core/constants/permissions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/enums/user_role.dart';

/// حالة `UsersCubit` الكاملة — Union Type مكتوب يدوياً (بلا `freezed`)،
/// بنفس نمط `EquipmentState`/`LeaveState`/`DocumentsState` تماماً: ثلاث
/// حالات فقط (`UsersLoading` / `UsersLoaded` / `UsersError`). 🆕
/// (Prompt 26)
sealed class UsersState {
  const UsersState();

  T when<T>({
    required T Function() loading,
    required T Function(UsersData data) loaded,
    required T Function(Failure failure) error,
  }) {
    final UsersState state = this;
    return switch (state) {
      UsersLoading() => loading(),
      UsersLoaded(:final data) => loaded(data),
      UsersError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(UsersData data)? loaded,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      loaded: loaded ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  /// [UsersData] الحالية إن كانت الحالة [UsersLoaded]، أو `null` —
  /// بنفس نمط `LeaveState.dataOrNull`.
  UsersData? get dataOrNull => maybeWhen<UsersData?>(
        orElse: () => null,
        loaded: (UsersData d) => d,
      );
}

/// جارٍ التحميل الأولي (كل أعضاء الشركة).
final class UsersLoading extends UsersState {
  const UsersLoading();
}

/// جاهزة لعرض `users_list.dart`/`user_details.dart`/
/// `user_roles_edit.dart`/`invite_user.dart` معاً.
final class UsersLoaded extends UsersState {
  const UsersLoaded(this.data);

  final UsersData data;
}

/// فشل تعذّر معه تحميل أي بيانات إطلاقاً.
final class UsersError extends UsersState {
  const UsersError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة إدارة المستخدمين المجمّعة — يحملها [UsersLoaded]
/// وحدها.
class UsersData {
  const UsersData({
    required this.currentUser,
    this.members = const <AppUser>[],
    this.selectedMemberId,
    this.searchQuery = '',
    this.roleFilter,
    this.activeOnly = true,
    this.isRefreshing = false,
    this.isSavingRole = false,
    this.isSavingStatus = false,
    this.isInviting = false,
    this.inviteErrorMessage,
  });

  final AppUser currentUser;

  /// كل أعضاء الشركة (كل الأدوار والحالات معاً) — `users_list.dart`
  /// عبر `GetCompanyMembersUsecase`.
  final List<AppUser> members;

  /// عضوية `company_members.id` المختارة حالياً لعرضها في لوحة
  /// `user_details.dart` الجانبية — معرّف وليس نسخة كاملة، حتى يبقى
  /// [selectedMember] متزامناً تلقائياً مع [members] بعد كل تحديث/
  /// تحديث، بنفس منطق `EquipmentData.selectedEquipment` لكن عبر معرّف
  /// بدل كائن كامل لتفادي نسخة قديمة معروضة بعد تعديل الدور/الحالة.
  final String? selectedMemberId;

  /// نص بحث حرّ (بالاسم الكامل/الهاتف/المسمى الوظيفي) — `users_list.dart`.
  final String searchQuery;

  final UserRole? roleFilter;

  /// `true` (الافتراضي): يعرض الأعضاء النشطين فقط. `false`: المعطَّلين
  /// فقط. `null`: الكل معاً — `users_list.dart`.
  final bool? activeOnly;

  final bool isRefreshing;

  /// حفظ تعديل دور جارٍ — `user_roles_edit.dart`.
  final bool isSavingRole;

  /// حفظ تفعيل/تعطيل جارٍ — `user_details.dart`.
  final bool isSavingStatus;

  /// إرسال دعوة جارٍ — `invite_user.dart`.
  final bool isInviting;

  /// رسالة فشل آخر محاولة دعوة (مثال: "يوجد عضو بهذا البريد بالفعل")
  /// — `null` عند عدم وجود فشل حديث، بنفس نمط
  /// `LeaveData.submitErrorMessage`.
  final String? inviteErrorMessage;

  /// صحيح إن ملك [currentUser] صلاحية عرض قائمة المستخدمين أصلاً —
  /// [Permission.usersView] (foreman فأعلى)؛ حارس المسار
  /// (`RoleGuard`) يتحقق منها أصلاً قبل الدخول، لكنها مفيدة أيضاً
  /// كتحقّق دفاعي إضافي هنا.
  bool get canView =>
      RolePermissions.has(currentUser.role, Permission.usersView);

  /// صحيح إن ملك [currentUser] صلاحية دعوة أعضاء جدد —
  /// [Permission.usersInvite] (projectManager فأعلى) — `invite_user.dart`.
  bool get canInvite =>
      RolePermissions.has(currentUser.role, Permission.usersInvite);

  /// صحيح إن ملك [currentUser] صلاحية تعديل أدوار الأعضاء —
  /// [Permission.usersEditRoles] (admin فقط) — `user_roles_edit.dart`.
  bool get canEditRoles =>
      RolePermissions.has(currentUser.role, Permission.usersEditRoles);

  /// صحيح إن ملك [currentUser] صلاحية تفعيل/تعطيل عضوية —
  /// [Permission.usersDeactivate] (admin فقط) — `user_details.dart`.
  bool get canDeactivate =>
      RolePermissions.has(currentUser.role, Permission.usersDeactivate);

  /// [members] بعد تطبيق [searchQuery]/[roleFilter]/[activeOnly]
  /// معاً، مرتّبة بحسب الاسم الكامل (كما وردت من `getCompanyMembers`
  /// نفسها أصلاً) — `users_list.dart`.
  List<AppUser> get filteredMembers {
    final String query = searchQuery.trim().toLowerCase();
    return members.where((AppUser m) {
      final bool matchesQuery = query.isEmpty ||
          m.fullName.toLowerCase().contains(query) ||
          (m.phone?.toLowerCase().contains(query) ?? false) ||
          (m.jobTitle?.toLowerCase().contains(query) ?? false);
      final bool matchesRole = roleFilter == null || m.role == roleFilter;
      final bool matchesStatus =
          activeOnly == null || m.isActive == activeOnly;
      return matchesQuery && matchesRole && matchesStatus;
    }).toList(growable: false);
  }

  /// العضو المختار حالياً (يُشتق من [members] عبر [selectedMemberId] —
  /// انظر توثيق القرار الكامل أعلى الحقل نفسه)، أو `null`.
  AppUser? get selectedMember {
    if (selectedMemberId == null) return null;
    for (final AppUser m in members) {
      if (m.id == selectedMemberId) return m;
    }
    return null;
  }

  UsersData copyWith({
    AppUser? currentUser,
    List<AppUser>? members,
    String? selectedMemberId,
    bool clearSelectedMember = false,
    String? searchQuery,
    UserRole? roleFilter,
    bool clearRoleFilter = false,
    bool? activeOnly,
    bool clearActiveOnlyFilter = false,
    bool? isRefreshing,
    bool? isSavingRole,
    bool? isSavingStatus,
    bool? isInviting,
    String? inviteErrorMessage,
    bool clearInviteErrorMessage = false,
  }) {
    return UsersData(
      currentUser: currentUser ?? this.currentUser,
      members: members ?? this.members,
      selectedMemberId: clearSelectedMember
          ? null
          : (selectedMemberId ?? this.selectedMemberId),
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      activeOnly: clearActiveOnlyFilter
          ? null
          : (activeOnly ?? this.activeOnly),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSavingRole: isSavingRole ?? this.isSavingRole,
      isSavingStatus: isSavingStatus ?? this.isSavingStatus,
      isInviting: isInviting ?? this.isInviting,
      inviteErrorMessage: clearInviteErrorMessage
          ? null
          : (inviteErrorMessage ?? this.inviteErrorMessage),
    );
  }
}
