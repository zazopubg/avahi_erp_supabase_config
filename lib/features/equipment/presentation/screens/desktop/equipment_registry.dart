import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/equipment.dart';
import '../../../../../domain/enums/equipment_status.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/equipment_cubit.dart';
import '../../state/equipment_state.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/equipment_status_badge.dart';
import 'equipment_details.dart';
import 'maintenance_schedule.dart';

/// واجهة سجل المعدات الكاملة لسطح المكتب — نظير `my_equipment_screen.dart`
/// (الهاتف، محصور بمعدات المستخدم الحالي فقط) لكن بنطاق كامل: كل
/// معدات الشركة، بحث وتصفية حسب الحالة، وضعا عرض ("سجل المعدات" مقابل
/// "جدول الصيانة" عبر [MaintenanceSchedule]) — تخطيط عمودين مطابق
/// لـ `documents_manager.dart` تماماً (لوحة تفاصيل جانبية
/// [EquipmentDetailsPanel] عند اختيار معدة).
///
/// تفترض وجود `BlocProvider<EquipmentCubit>` مزوَّد مسبقاً من الشجرة
/// الأعلى (`my_equipment_screen.dart` — نقطة الدخول الموحَّدة لمسار
/// `RouteNames.equipment`، انظر توثيق القرار الكامل هناك).
class EquipmentRegistry extends StatelessWidget {
  const EquipmentRegistry({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EquipmentCubit, EquipmentState>(
      builder: (BuildContext context, EquipmentState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('سجل المعدات')),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل سجل المعدات...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل سجل المعدات',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<EquipmentCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (EquipmentData data) => _RegistryBody(data: data),
          ),
        );
      },
    );
  }
}

enum _ViewMode { registry, maintenance }

class _RegistryBody extends StatefulWidget {
  const _RegistryBody({required this.data});

  final EquipmentData data;

  @override
  State<_RegistryBody> createState() => _RegistryBodyState();
}

class _RegistryBodyState extends State<_RegistryBody> {
  _ViewMode _viewMode = _ViewMode.registry;

  @override
  Widget build(BuildContext context) {
    final EquipmentCubit cubit = context.read<EquipmentCubit>();
    final EquipmentData data = widget.data;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _viewMode == _ViewMode.registry
                            ? '${data.filteredEquipment.length} معدة'
                            : '${data.maintenanceDueEquipment.length} معدة مستحقة للصيانة',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: AvahiSpacing.sm),
                    SegmentedButton<_ViewMode>(
                      segments: const <ButtonSegment<_ViewMode>>[
                        ButtonSegment<_ViewMode>(
                          value: _ViewMode.registry,
                          icon: Icon(Icons.list_alt_outlined),
                          label: Text('سجل المعدات'),
                        ),
                        ButtonSegment<_ViewMode>(
                          value: _ViewMode.maintenance,
                          icon: Icon(Icons.build_outlined),
                          label: Text('جدول الصيانة'),
                        ),
                      ],
                      selected: <_ViewMode>{_viewMode},
                      onSelectionChanged: (Set<_ViewMode> selected) =>
                          setState(() => _viewMode = selected.first),
                    ),
                  ],
                ),
                const SizedBox(height: AvahiSpacing.sm),
                if (_viewMode == _ViewMode.registry) ...<Widget>[
                  _RegistryFilterBar(data: data, cubit: cubit),
                  const SizedBox(height: AvahiSpacing.sm),
                ],
                Expanded(
                  child: _viewMode == _ViewMode.maintenance
                      ? MaintenanceSchedule(cubit: cubit, data: data)
                      : _RegistryList(data: data, cubit: cubit),
                ),
              ],
            ),
          ),
        ),
        if (data.selectedEquipment != null)
          EquipmentDetailsPanel(
            cubit: cubit,
            equipment: data.selectedEquipment!,
            data: data,
          ),
      ],
    );
  }
}

class _RegistryFilterBar extends StatelessWidget {
  const _RegistryFilterBar({required this.data, required this.cubit});

  final EquipmentData data;
  final EquipmentCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: AvahiTextField(
            hint: 'ابحث بالاسم أو النوع أو الرقم التسلسلي...',
            prefixIcon: Icons.search,
            onChanged: cubit.setSearchQuery,
          ),
        ),
        const SizedBox(width: AvahiSpacing.sm),
        Expanded(
          child: AvahiDropdown<EquipmentStatus?>(
            label: 'الحالة',
            value: data.statusFilter,
            items: <AvahiDropdownItem<EquipmentStatus?>>[
              const AvahiDropdownItem<EquipmentStatus?>(
                value: null,
                label: 'كل الحالات',
              ),
              for (final EquipmentStatus status in EquipmentStatus.values)
                AvahiDropdownItem<EquipmentStatus?>(
                  value: status,
                  label: equipmentStatusVisuals(status).$1,
                ),
            ],
            onChanged: cubit.setStatusFilter,
          ),
        ),
        if (data.hasActiveFilters) ...<Widget>[
          const SizedBox(width: AvahiSpacing.xs),
          IconButton(
            tooltip: 'مسح الفلاتر',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: cubit.clearFilters,
          ),
        ],
      ],
    );
  }
}

class _RegistryList extends StatelessWidget {
  const _RegistryList({required this.data, required this.cubit});

  final EquipmentData data;
  final EquipmentCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (data.isEquipmentLoading) {
      return const LoadingIndicator();
    }

    final List<Equipment> equipment = data.filteredEquipment;
    if (equipment.isEmpty) {
      return EmptyState(
        title: data.hasActiveFilters
            ? 'لا نتائج مطابقة للفلاتر'
            : 'لا توجد معدات مسجَّلة بعد',
        message: data.hasActiveFilters
            ? 'جرّب تعديل معايير البحث أو الحالة.'
            : 'أضف معدات الشركة عبر لوحة الإدارة.',
        icon: Icons.construction_outlined,
      );
    }

    return ListView.separated(
      itemCount: equipment.length,
      separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final Equipment item = equipment[index];
        return EquipmentCard(
          equipment: item,
          projectLabel: item.projectId == null
              ? null
              : data.projectsById[item.projectId]?.name,
          onTap: () => cubit.selectEquipment(item),
        );
      },
    );
  }
}
