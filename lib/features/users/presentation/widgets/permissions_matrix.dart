import 'package:flutter/material.dart';

import '../../../../core/constants/permissions.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../navigation/role_labels.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';

/// تسمية عربية موحّدة لكل [Permission] — مخصّصة حصراً لعرضها ضمن
/// [PermissionsMatrix] (لا مستهلك آخر لها حالياً)، لذا عُرِّفت هنا
/// مباشرة بدل ملف عام تحت `core/constants/` — بنفس منطق `role_labels.dart`
/// (تسمية عرض بحتة، لا علاقة لها بالتخزين/`Permission.name`).
String _permissionLabel(Permission permission) {
  return switch (permission) {
    Permission.attendanceCheckInSelf => 'تسجيل حضور شخصي',
    Permission.attendanceApproveTeam => 'اعتماد حضور الفريق',
    Permission.attendanceViewAll => 'عرض كل سجلات الحضور',
    Permission.attendanceEditRecords => 'تعديل سجلات الحضور',
    Permission.tasksViewAssigned => 'عرض المهام المُسندة',
    Permission.tasksCreate => 'إنشاء مهام',
    Permission.tasksAssign => 'إسناد مهام',
    Permission.tasksEditAny => 'تعديل أي مهمة',
    Permission.tasksDeleteAny => 'حذف أي مهمة',
    Permission.fieldReportsCreate => 'إنشاء تقارير ميدانية',
    Permission.fieldReportsViewTeam => 'عرض تقارير الفريق',
    Permission.fieldReportsViewAll => 'عرض كل التقارير',
    Permission.fieldReportsApprove => 'اعتماد التقارير',
    Permission.photosUpload => 'رفع صور',
    Permission.photosViewAll => 'عرض كل الصور',
    Permission.photosDeleteAny => 'حذف أي صورة',
    Permission.punchListCreate => 'إنشاء ملاحظة',
    Permission.punchListResolve => 'معالجة ملاحظة',
    Permission.punchListCloseOut => 'إغلاق ملاحظة',
    Permission.projectsView => 'عرض المشاريع',
    Permission.projectsCreate => 'إنشاء مشروع',
    Permission.projectsEdit => 'تعديل مشروع',
    Permission.projectsArchive => 'أرشفة مشروع',
    Permission.documentsView => 'عرض المستندات',
    Permission.documentsUpload => 'رفع مستندات',
    Permission.documentsDeleteAny => 'حذف أي مستند',
    Permission.equipmentView => 'عرض المعدات',
    Permission.equipmentAssign => 'إسناد معدات',
    Permission.equipmentManage => 'إدارة سجل المعدات',
    Permission.leaveRequestSubmit => 'تقديم طلب إجازة',
    Permission.leaveRequestApproveTeam => 'اعتماد إجازات الفريق',
    Permission.leaveRequestViewAll => 'عرض كل طلبات الإجازة',
    Permission.analyticsViewTeam => 'تحليلات الفريق',
    Permission.analyticsViewProject => 'تحليلات المشروع',
    Permission.analyticsViewTenantWide => 'تحليلات الشركة كاملة',
    Permission.usersView => 'عرض المستخدمين',
    Permission.usersInvite => 'دعوة مستخدمين',
    Permission.usersEditRoles => 'تعديل الأدوار',
    Permission.usersDeactivate => 'تفعيل/تعطيل مستخدمين',
    Permission.settingsEditTenant => 'تعديل إعدادات الشركة',
    Permission.settingsManageBranding => 'إدارة الهوية البصرية',
    Permission.platformManageTenants => 'إدارة المستأجرين',
    Permission.platformViewAllData => 'عرض بيانات كل المستأجرين',
    Permission.platformExportTenantData => 'تصدير بيانات مستأجر',
  };
}

/// فئة صلاحيات واحدة (عنوان + قائمة صلاحياتها) — تُبنى منها صفوف
/// [PermissionsMatrix] مُجمَّعة بدل عرض 40+ صلاحية مسطَّحة دفعة واحدة.
class _PermissionGroup {
  const _PermissionGroup(this.title, this.permissions);

  final String title;
  final List<Permission> permissions;
}

const List<_PermissionGroup> _groups = <_PermissionGroup>[
  _PermissionGroup('الحضور', <Permission>[
    Permission.attendanceCheckInSelf,
    Permission.attendanceApproveTeam,
    Permission.attendanceViewAll,
    Permission.attendanceEditRecords,
  ]),
  _PermissionGroup('المهام', <Permission>[
    Permission.tasksViewAssigned,
    Permission.tasksCreate,
    Permission.tasksAssign,
    Permission.tasksEditAny,
    Permission.tasksDeleteAny,
  ]),
  _PermissionGroup('التقارير الميدانية', <Permission>[
    Permission.fieldReportsCreate,
    Permission.fieldReportsViewTeam,
    Permission.fieldReportsViewAll,
    Permission.fieldReportsApprove,
  ]),
  _PermissionGroup('الصور', <Permission>[
    Permission.photosUpload,
    Permission.photosViewAll,
    Permission.photosDeleteAny,
  ]),
  _PermissionGroup('قوائم الملاحظات', <Permission>[
    Permission.punchListCreate,
    Permission.punchListResolve,
    Permission.punchListCloseOut,
  ]),
  _PermissionGroup('المشاريع', <Permission>[
    Permission.projectsView,
    Permission.projectsCreate,
    Permission.projectsEdit,
    Permission.projectsArchive,
  ]),
  _PermissionGroup('المستندات', <Permission>[
    Permission.documentsView,
    Permission.documentsUpload,
    Permission.documentsDeleteAny,
  ]),
  _PermissionGroup('المعدات', <Permission>[
    Permission.equipmentView,
    Permission.equipmentAssign,
    Permission.equipmentManage,
  ]),
  _PermissionGroup('طلبات الإجازة', <Permission>[
    Permission.leaveRequestSubmit,
    Permission.leaveRequestApproveTeam,
    Permission.leaveRequestViewAll,
  ]),
  _PermissionGroup('التحليلات', <Permission>[
    Permission.analyticsViewTeam,
    Permission.analyticsViewProject,
    Permission.analyticsViewTenantWide,
  ]),
  _PermissionGroup('المستخدمون', <Permission>[
    Permission.usersView,
    Permission.usersInvite,
    Permission.usersEditRoles,
    Permission.usersDeactivate,
  ]),
  _PermissionGroup('الإعدادات', <Permission>[
    Permission.settingsEditTenant,
    Permission.settingsManageBranding,
  ]),
  _PermissionGroup('إدارة المنصّة', <Permission>[
    Permission.platformManageTenants,
    Permission.platformViewAllData,
    Permission.platformExportTenantData,
  ]),
];

/// جدول بصري توضيحي (أدوار × صلاحيات) — للعرض فقط، بلا أي إجراء
/// تفاعلي (لا يُعدِّل صلاحيات فعلية؛ تعديل الأدوار الفعلي يتم لعضو
/// واحد في كل مرة عبر `user_roles_edit.dart`) — يشرح للأدمن ماذا يعني
/// كل دور عملياً قبل اختياره لعضو ما. مُستبعد عمداً دور
/// [UserRole.platformOwner] من الأعمدة (خارج نطاق أدوار المستأجر
/// الواحد التي يديرها هذا الأدمن أصلاً — لا معنى لعرضه هنا).
///
/// مكوّن عرض بحت — يعتمد فقط على `RolePermissions.has` الثابتة
/// (`core/constants/permissions.dart`)، بلا أي استدعاء شبكة.
class PermissionsMatrix extends StatelessWidget {
  const PermissionsMatrix({super.key});

  static const List<UserRole> _tenantRoles = <UserRole>[
    UserRole.worker,
    UserRole.foreman,
    UserRole.engineer,
    UserRole.projectManager,
    UserRole.admin,
  ];

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: AvahiRadius.radiusMd,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll<Color>(colors.surfaceVariant),
          columns: <DataColumn>[
            const DataColumn(label: Text('الصلاحية')),
            for (final UserRole role in _tenantRoles)
              DataColumn(label: Text(role.displayLabel)),
          ],
          rows: <DataRow>[
            for (final _PermissionGroup group in _groups) ...<DataRow>[
              DataRow(
                color: WidgetStatePropertyAll<Color>(colors.surfaceVariant.withValues(alpha: 0.5)),
                cells: <DataCell>[
                  DataCell(
                    Text(
                      group.title,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (int i = 0; i < _tenantRoles.length; i++)
                    DataCell.empty,
                ],
              ),
              for (final Permission permission in group.permissions)
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text(_permissionLabel(permission))),
                    for (final UserRole role in _tenantRoles)
                      DataCell(
                        Center(
                          child: RolePermissions.has(role, permission)
                              ? Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: colors.success,
                                )
                              : Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
