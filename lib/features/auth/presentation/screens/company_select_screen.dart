import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/company.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../state/auth_cubit.dart';
import '../state/auth_state.dart';
import '../widgets/company_card.dart';

/// شاشة اختيار الشركة — تُعرض فقط عند [AuthNeedsCompanySelection]
/// (تعدد عضويات نشطة لنفس المستخدم). لمسة على [CompanyCard] تستدعي
/// `AuthCubit.selectCompany` مباشرة؛ نجاحها يصدر [AuthAuthenticated]
/// فتتنقّل هذه الشاشة إلى `/home` عبر `listener`.
///
/// ⚠️ إن وصل المستخدم لهذا المسار مباشرة (تنقّل يدوي/رابط محفوظ) دون
/// حالة [AuthNeedsCompanySelection] فعلية (مثال: بعد إعادة تحميل
/// الصفحة قبل انتهاء `checkAuthStatus`)، تُعرض حالة تحميل بدل شاشة
/// فارغة مضلِّلة، بانتظار صدور الحالة الصحيحة من [AuthCubit].
class CompanySelectScreen extends StatelessWidget {
  const CompanySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر الشركة')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (BuildContext context, AuthState state) {
          state.whenOrNull(
            authenticated: (_, __) => context.goNamed(RouteNames.home),
            error: (Failure failure) => context.showSnackBar(failure.message),
          );
        },
        builder: (BuildContext context, AuthState state) {
          return state.maybeWhen(
            needsCompanySelection: (List<Company> companies) {
              if (companies.isEmpty) {
                return const EmptyState(
                  title: 'لا توجد شركات متاحة',
                  message: 'تعذّر تحميل بيانات الشركات المرتبطة بحسابك.',
                  icon: Icons.domain_disabled_outlined,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AvahiSpacing.md),
                itemCount: companies.length,
                itemBuilder: (BuildContext context, int index) {
                  final Company company = companies[index];
                  return CompanyCard(
                    company: company,
                    onTap: () =>
                        context.read<AuthCubit>().selectCompany(company),
                  );
                },
              );
            },
            orElse: () => const LoadingIndicator(),
          );
        },
      ),
    );
  }
}
