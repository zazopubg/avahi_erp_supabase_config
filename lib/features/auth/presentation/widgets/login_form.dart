import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';

/// نموذج تسجيل الدخول (بريد + كلمة مرور) — مكوّن عرض بحت بلا أي منطق
/// مصادقة فعلي؛ يستدعي [onSubmit] فقط بعد اجتياز التحقق المحلي
/// (`Validators`)، تاركاً استدعاء `AuthCubit.login` فعلياً لـ
/// `login_screen.dart`.
class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.onSubmit,
    super.key,
    this.isLoading = false,
    this.errorText,
  });

  /// يُستدعى ببريد وكلمة مرور صالحين محلياً فقط (بعد نجاح
  /// `Form.validate()`).
  final void Function(String email, String password) onSubmit;

  final bool isLoading;

  /// رسالة خطأ من طبقة الخادم (بيانات دخول خاطئة، فشل شبكة...) —
  /// منفصلة عن أخطاء التحقق المحلي الفورية.
  final String? errorText;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AvahiTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'name@company.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            validator: Validators.email,
            onSubmitted: (_) =>
                FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: AvahiSpacing.md),
          AvahiTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            validator: Validators.password,
            onSubmitted: (_) => _handleSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          if (widget.errorText != null) ...<Widget>[
            const SizedBox(height: AvahiSpacing.sm),
            Text(
              widget.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AvahiSpacing.lg),
          AvahiButton(
            label: 'تسجيل الدخول',
            isFullWidth: true,
            isLoading: widget.isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
