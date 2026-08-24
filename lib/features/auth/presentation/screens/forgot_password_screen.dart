import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';
import '../state/auth_cubit.dart';

/// شاشة استعادة كلمة المرور — نموذج بريد واحد يرسل رسالة إعادة تعيين
/// عبر `AuthCubit.sendPasswordResetEmail`. حالة مستقلة تماماً عن
/// [AuthState] العامة (انظر توثيق `AuthCubit.sendPasswordResetEmail`)،
/// لأن نجاح/فشل هذه العملية لا يمثّل تغيّراً في حالة مصادقة المستخدم
/// نفسه.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _emailSent = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final ResultOf<void> result = await context
        .read<AuthCubit>()
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    result.fold(
      (Failure failure) => setState(() {
        _isSubmitting = false;
        _errorText = failure.message;
      }),
      (_) => setState(() {
        _isSubmitting = false;
        _emailSent = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.goNamed(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AvahiSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _emailSent ? _buildSuccess(context) : _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'استعادة كلمة المرور',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: AvahiSpacing.xs),
          Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: AvahiSpacing.xl),
          AvahiTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSubmitting,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: AvahiSpacing.sm),
            Text(_errorText!, style: TextStyle(color: context.colors.error)),
          ],
          const SizedBox(height: AvahiSpacing.lg),
          AvahiButton(
            label: 'إرسال رابط الاستعادة',
            isFullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.mark_email_read_outlined, size: 56, color: context.colors.primary),
        const SizedBox(height: AvahiSpacing.md),
        Text(
          'تحقّق من بريدك الإلكتروني',
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: AvahiSpacing.xs),
        Text(
          'أرسلنا رابط إعادة تعيين كلمة المرور إلى ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: AvahiSpacing.lg),
        AvahiButton(
          label: 'العودة لتسجيل الدخول',
          isFullWidth: true,
          onPressed: () => context.goNamed(RouteNames.login),
        ),
      ],
    );
  }
}
