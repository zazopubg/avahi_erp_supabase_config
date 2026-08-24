import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/validators.dart';
import '../../../../../domain/entities/company.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../state/platform_admin_cubit.dart';
import '../../state/platform_admin_state.dart';

/// شاشة إنشاء مستأجر (شركة) جديد — تُفتح عبر `Navigator.push` من
/// `tenants_list.dart` (زر "إضافة مستأجر"). عند الإرسال تستدعي
/// [PlatformAdminCubit.createTenant]، والتي بدورها تستدعي Edge
/// Function `create-company` (`service_role`) — انظر توثيق القرار
/// الكامل في `IPlatformAdminRepository.createTenant`. 🆕 (Prompt 28)
///
/// ⚠️ قرار تصميم (`slug` نمط صارم موحّى محلياً، بلا اعتماد على
/// `Validators` العامة): الخادم (`create-company/index.ts`) يفرض
/// `SLUG_PATTERN = /^[a-z0-9-]+$/` بصرامة — [_slugPattern] هنا مطابق
/// له حرفياً كتحقق فوري في الواجهة قبل الإرسال، بدل الانتظار لرفض
/// الخادم فقط.
class TenantCreateScreen extends StatefulWidget {
  const TenantCreateScreen({super.key});

  @override
  State<TenantCreateScreen> createState() => _TenantCreateScreenState();
}

class _TenantCreateScreenState extends State<TenantCreateScreen> {
  static final RegExp _slugPattern = RegExp(r'^[a-z0-9-]+$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _timezoneController =
      TextEditingController(text: 'Asia/Baghdad');
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _adminUserIdController = TextEditingController();
  final TextEditingController _adminFullNameController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _slugController.dispose();
    _timezoneController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _adminUserIdController.dispose();
    _adminFullNameController.dispose();
    super.dispose();
  }

  String? _validateSlug(String? value) {
    final String? required = Validators.required(value);
    if (required != null) return required;
    if (!_slugPattern.hasMatch(value!.trim())) {
      return 'يُسمح فقط بأحرف لاتينية صغيرة وأرقام وشرطات (-).';
    }
    return null;
  }

  Future<void> _submit(PlatformAdminCubit cubit) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_adminUserIdController.text.trim().isNotEmpty &&
        _adminFullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اسم المدير مطلوب عند إدخال معرّف المستخدم.'),
        ),
      );
      return;
    }

    final Company? created = await cubit.createTenant(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      nameAr: _nameArController.text.trim().isEmpty
          ? null
          : _nameArController.text.trim(),
      timezone: _timezoneController.text.trim().isEmpty
          ? null
          : _timezoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      initialAdminUserId: _adminUserIdController.text.trim().isEmpty
          ? null
          : _adminUserIdController.text.trim(),
      initialAdminFullName: _adminFullNameController.text.trim().isEmpty
          ? null
          : _adminFullNameController.text.trim(),
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء مستأجر "${created.name}" بنجاح.')),
      );
    }
    // عند الفشل: `PlatformAdminData.createTenantErrorMessage` يُعرض
    // ضمن نفس الشاشة أدناه (بلا إغلاق) — بنفس نمط
    // `UsersData.inviteErrorMessage` في `invite_user.dart`.
  }

  @override
  Widget build(BuildContext context) {
    final PlatformAdminCubit cubit = context.read<PlatformAdminCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مستأجر جديد')),
      body: BlocBuilder<PlatformAdminCubit, PlatformAdminState>(
        builder: (BuildContext context, PlatformAdminState state) {
          final PlatformAdminData? data = state.dataOrNull;
          final bool isCreating = data?.isCreatingTenant ?? false;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AvahiSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'بيانات الشركة',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _nameController,
                        label: 'الاسم (بالإنجليزية)',
                        validator: Validators.required,
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _nameArController,
                        label: 'الاسم بالعربية (اختياري)',
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _slugController,
                        label: 'الـ Slug (لاتيني، بدون مسافات)',
                        hint: 'modern-construction',
                        validator: _validateSlug,
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _timezoneController,
                        label: 'المنطقة الزمنية',
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _addressController,
                        label: 'العنوان (اختياري)',
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _phoneController,
                        label: 'الهاتف (اختياري)',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AvahiSpacing.lg),
                      Text(
                        'أول مدير للشركة (اختياري)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AvahiSpacing.xxs),
                      Text(
                        'إن كان المستخدم مسجَّلاً في نظام المصادقة مسبقاً '
                        '(auth.users)، يمكن إسناده كمدير مباشرة للشركة '
                        'الجديدة.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _adminUserIdController,
                        label: 'معرّف المستخدم (UUID) — اختياري',
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      AvahiTextField(
                        controller: _adminFullNameController,
                        label: 'اسم المدير الكامل — مطلوب إن أُدخل المعرّف أعلاه',
                      ),
                      if (data?.createTenantErrorMessage != null) ...<Widget>[
                        const SizedBox(height: AvahiSpacing.sm),
                        Text(
                          data!.createTenantErrorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                      const SizedBox(height: AvahiSpacing.lg),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AvahiButton(
                              label: 'إلغاء',
                              variant: AvahiButtonVariant.secondary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: AvahiSpacing.sm),
                          Expanded(
                            child: AvahiButton(
                              label: 'إنشاء المستأجر',
                              icon: Icons.add_business_outlined,
                              isLoading: isCreating,
                              onPressed: () => _submit(cubit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
