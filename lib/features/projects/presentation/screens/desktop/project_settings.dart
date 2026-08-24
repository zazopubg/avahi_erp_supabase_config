import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/project.dart';
import '../../../../../domain/enums/project_status.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/projects_cubit.dart';
import '../../state/projects_state.dart';
import '../../widgets/project_status_badge.dart';
import '../shared/project_route_args.dart';

/// إعدادات المشروع الأساسية — الاسم، الرمز، العميل، النطاق الجغرافي
/// (العنوان النصي/الإحداثيات/نصف قطر الجيوفنسينغ المستخدم في تسجيل
/// الحضور، Prompt 15)، الوصف، وحالة المشروع. مسار مستقل
/// `/projects/:id/settings`، يُفتح من زر "الإعدادات" في
/// `project_details.dart`.
///
/// ⚠️ "إرشادات السلامة" المذكورة في نطاق Prompt 20 تُدمج هنا ضمن حقل
/// [Project.description] العام (لا يوجد عمود مخصص `safetyGuidelines`
/// في `public.projects` — انظر `003_create_projects.sql`) عبر تسمية
/// واضحة لقسم النموذج، تفادياً لهجرة قاعدة بيانات إضافية خارج نطاق
/// هذه الخطوة.
class ProjectSettingsScreen extends StatefulWidget {
  const ProjectSettingsScreen({required this.args, super.key});

  final ProjectRouteArgs args;

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _geofenceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  ProjectStatus _status = ProjectStatus.active;
  bool _initialized = false;

  void _hydrate(Project project) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = project.name;
    _codeController.text = project.code ?? '';
    _clientController.text = project.clientName ?? '';
    _addressController.text = project.address ?? '';
    _geofenceController.text = project.geofenceRadiusMeters.toStringAsFixed(0);
    _descriptionController.text = project.description ?? '';
    _status = project.status;
  }

  @override
  void initState() {
    super.initState();
    final ProjectsData? data = widget.args.cubit.state.dataOrNull;
    if (data?.selectedProject?.id != widget.args.projectId) {
      widget.args.cubit.selectProject(widget.args.projectId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _clientController.dispose();
    _addressController.dispose();
    _geofenceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context, Project current) async {
    final ProjectsCubit cubit = context.read<ProjectsCubit>();
    final Project updated = current.copyWith(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      clientName:
          _clientController.text.trim().isEmpty ? null : _clientController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      geofenceRadiusMeters:
          double.tryParse(_geofenceController.text.trim()) ?? current.geofenceRadiusMeters,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      status: _status,
    );

    final bool ok = await cubit.updateSelectedProject(updated);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حفظ إعدادات المشروع بنجاح.' : 'تعذّر حفظ التغييرات.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectsCubit>.value(
      value: widget.args.cubit,
      child: BlocBuilder<ProjectsCubit, ProjectsState>(
        builder: (BuildContext context, ProjectsState state) {
          final ProjectsData? data = state.dataOrNull;
          final Project? project = data?.selectedProject;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.pop(),
              ),
              title: Text('إعدادات المشروع — ${project?.name ?? ''}'),
              actions: <Widget>[
                if (project != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
                    child: AvahiButton(
                      label: 'حفظ التغييرات',
                      icon: Icons.save_outlined,
                      isLoading: data?.isSubmitting ?? false,
                      onPressed: () => _save(context, project),
                    ),
                  ),
              ],
            ),
            body: state.maybeWhen<Widget>(
              orElse: () => const LoadingIndicator(),
              error: (Failure failure) =>
                  ErrorView(title: 'تعذّر تحميل بيانات المشروع', message: failure.message),
              loaded: (ProjectsData d) {
                final Project? p = d.selectedProject;
                if (p == null) return const LoadingIndicator();
                _hydrate(p);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AvahiSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'البيانات الأساسية',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ProjectStatusBadge(status: _status),
                            ],
                          ),
                          const SizedBox(height: AvahiSpacing.md),
                          AvahiTextField(controller: _nameController, label: 'اسم المشروع'),
                          const SizedBox(height: AvahiSpacing.sm),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: AvahiTextField(
                                  controller: _codeController,
                                  label: 'رمز المشروع',
                                ),
                              ),
                              const SizedBox(width: AvahiSpacing.sm),
                              Expanded(
                                child: AvahiTextField(
                                  controller: _clientController,
                                  label: 'اسم العميل',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AvahiSpacing.sm),
                          AvahiDropdown<ProjectStatus>(
                            value: _status,
                            label: 'حالة المشروع',
                            items: <AvahiDropdownItem<ProjectStatus>>[
                              for (final ProjectStatus s in ProjectStatus.values)
                                AvahiDropdownItem<ProjectStatus>(
                                  value: s,
                                  label: s.displayLabel,
                                ),
                            ],
                            onChanged: (ProjectStatus? s) {
                              if (s != null) setState(() => _status = s);
                            },
                          ),
                          const SizedBox(height: AvahiSpacing.lg),
                          const Text(
                            'النطاق الجغرافي',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AvahiSpacing.md),
                          AvahiTextField(
                            controller: _addressController,
                            label: 'العنوان',
                            prefixIcon: Icons.place_outlined,
                          ),
                          const SizedBox(height: AvahiSpacing.sm),
                          AvahiTextField(
                            controller: _geofenceController,
                            label: 'نصف قطر الجيوفنسينغ (بالأمتار)',
                            keyboardType: TextInputType.number,
                            helperText: 'يُستخدم للتحقق من موقع تسجيل الحضور.',
                          ),
                          const SizedBox(height: AvahiSpacing.lg),
                          const Text(
                            'الوصف وإرشادات السلامة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AvahiSpacing.md),
                          AvahiTextField(
                            controller: _descriptionController,
                            label: 'الوصف / إرشادات السلامة',
                            maxLines: 6,
                            hint: 'ملاحظات عامة عن المشروع، أو إرشادات سلامة خاصة بالموقع...',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
