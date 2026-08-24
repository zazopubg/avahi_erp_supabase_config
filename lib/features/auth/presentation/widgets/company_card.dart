import 'package:flutter/material.dart';

import '../../../../domain/entities/company.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avatar.dart';

/// بطاقة شركة واحدة ضمن `company_select_screen.dart` — تُعرض فقط عند
/// [AuthState.needsCompanySelection] (تعدد عضويات نشطة لنفس المستخدم).
/// مكوّن عرض بحت: لا يستدعي `AuthCubit.selectCompany` بنفسه، بل يبلّغ
/// [onTap] فقط.
class CompanyCard extends StatelessWidget {
  const CompanyCard({required this.company, required this.onTap, super.key});

  final Company company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AvahiSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Row(
            children: <Widget>[
              Avatar(imageUrl: company.logoUrl, name: company.name, size: AvatarSize.large),
              const SizedBox(width: AvahiSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      company.nameAr?.isNotEmpty == true ? company.nameAr! : company.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (company.address != null && company.address!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AvahiSpacing.xxs),
                      Text(
                        company.address!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
