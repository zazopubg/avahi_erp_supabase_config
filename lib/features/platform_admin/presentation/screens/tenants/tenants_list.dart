import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../domain/entities/company.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/status_badge.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';
import 'tenant_create.dart';
import 'tenant_details.dart';

/// لسان "المستأجرون" ضمن `admin_dashboard.dart` — جدول كل شركات
/// المنصّة (بلا فلترة `company_id`، بخلاف أي جدول آخر في التطبيق)، مع
/// بحث محلي بالاسم/الـ slug وزر إضافة مستأجر جديد. 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم (بحث محلي بلا حالة في Cubit، بخلاف `UsersData.searchQuery`):
/// بخلاف `UsersCubit` (بحث يُحفَظ ضمن الحالة المشتركة لأن لوحة
/// `user_details.dart` الجانبية تعتمد أيضاً على [UsersData] نفسها)،
/// هذه الشاشة تفتح تفاصيل المستأجر عبر مسار `Navigator.push` منفصل
/// تماماً (`TenantDetailsScreen`) لا يعتمد على نص بحث هذه الشاشة إطلاقاً
/// — فبقاء [_searchQuery] حالة محلية بسيطة (`StatefulWidget`) هنا أبسط
/// دون أي فائدة إضافية من رفعها لـ [PlatformAdminCubit].
class TenantsListScreen extends StatefulWidget {
  const TenantsListScreen({super.key});

  @override
  State<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
      builder: (BuildContext context, PlatformAdminState state) {
        final PlatformAdminData? data = state.dataOrNull;
        if (data == null) return const SizedBox.shrink();

        final String query = _searchQuery.trim().toLowerCase();
        final List<Company> filtered = data.companies.where((Company c) {
          if (query.isEmpty) return true;
          return c.name.toLowerCase().contains(query) ||
              c.slug.toLowerCase().contains(query) ||
              (c.nameAr?.toLowerCase().contains(query) ?? false);
        }).toList(growable: false);

        return Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: AvahiTextField(
                      label: 'بحث بالاسم أو الـ slug',
                      prefixIcon: Icons.search,
                      onChanged: (String value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: AvahiSpacing.sm),
                  AvahiButton(
                    label: 'إضافة مستأجر',
                    icon: Icons.add_business_outlined,
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider<PlatformAdminCubit>.value(
                          value: context.read<PlatformAdminCubit>(),
                          child: const TenantCreateScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AvahiSpacing.md),
              Expanded(
                child: DataGridRtl<Company>(
                  rows: filtered,
                  emptyTitle: 'لا يوجد مستأجرون مطابقون',
                  emptyIcon: Icons.apartment_outlined,
                  rowKeyOf: (Company c) => c.id,
                  onRowTap: (Company c) {
                    context.read<PlatformAdminCubit>().selectCompany(c);
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider<PlatformAdminCubit>.value(
                          value: context.read<PlatformAdminCubit>(),
                          child: TenantDetailsScreen(companyId: c.id),
                        ),
                      ),
                    );
                  },
                  columns: <DataGridColumn<Company>>[
                    DataGridColumn<Company>(
                      label: 'الاسم',
                      flex: 3,
                      cellBuilder: (BuildContext context, Company c) => Text(
                        c.nameAr?.isNotEmpty == true ? c.nameAr! : c.name,
                      ),
                    ),
                    DataGridColumn<Company>(
                      label: 'الـ Slug',
                      flex: 2,
                      cellBuilder: (BuildContext context, Company c) =>
                          Text(c.slug),
                    ),
                    DataGridColumn<Company>(
                      label: 'الحالة',
                      cellBuilder: (BuildContext context, Company c) =>
                          StatusBadge(
                        label: c.isActive ? 'نشطة' : 'معطَّلة',
                        status:
                            c.isActive ? AvahiStatus.success : AvahiStatus.neutral,
                        dense: true,
                      ),
                    ),
                    DataGridColumn<Company>(
                      label: 'تاريخ الإنشاء',
                      flex: 2,
                      cellBuilder: (BuildContext context, Company c) => Text(
                        DateFormatter.shortDate(c.createdAt),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
