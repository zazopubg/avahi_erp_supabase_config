import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../state/auth_cubit.dart';
import '../widgets/pin_keypad.dart';

/// شاشة رمز PIN السريع — تعمل بوضعين حسب وجود رمز محفوظ مسبقاً على
/// الجهاز ([AuthCubit.hasPinConfigured]):
/// 1. **إنشاء**: لا يوجد رمز محفوظ → يُطلب إدخال [AppConstants.pinLength]
///    أرقام مرتين (إدخال ثم تأكيد مطابق) قبل حفظه ([AuthCubit.createPin]).
/// 2. **تحقق**: يوجد رمز محفوظ → إدخال واحد يُقارَن مباشرة
///    ([AuthCubit.verifyPin])؛ عند الفشل يُمسح الإدخال مع رسالة خطأ.
///
/// لا علاقة لهذه الشاشة بإعادة المصادقة الكاملة لدى Supabase — الجلسة
/// الفعلية محفوظة أصلاً عبر `SessionService`، والـ PIN بوابة دخول سريعة
/// محلية فقط بعد نجاحها.
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

enum _PinMode { loading, create, confirm, verify }

class _PinScreenState extends State<PinScreen> {
  _PinMode _mode = _PinMode.loading;
  String _entered = '';
  String _firstEntry = '';
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bool hasPin = await context.read<AuthCubit>().hasPinConfigured();
    if (!mounted) return;
    setState(() => _mode = hasPin ? _PinMode.verify : _PinMode.create);
  }

  void _onDigit(String digit) {
    if (_isSubmitting || _entered.length >= AppConstants.pinLength) return;
    setState(() {
      _errorText = null;
      _entered += digit;
    });
    if (_entered.length == AppConstants.pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_isSubmitting || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    switch (_mode) {
      case _PinMode.create:
        setState(() {
          _firstEntry = _entered;
          _entered = '';
          _mode = _PinMode.confirm;
        });
        return;
      case _PinMode.confirm:
        if (_entered != _firstEntry) {
          setState(() {
            _entered = '';
            _mode = _PinMode.create;
            _errorText = 'الرمزان غير متطابقين، حاول من جديد.';
          });
          return;
        }
        setState(() => _isSubmitting = true);
        await context.read<AuthCubit>().createPin(_entered);
        if (!mounted) return;
        context.goNamed(RouteNames.home);
        return;
      case _PinMode.verify:
        setState(() => _isSubmitting = true);
        final bool ok = await context.read<AuthCubit>().verifyPin(_entered);
        if (!mounted) return;
        if (ok) {
          context.goNamed(RouteNames.home);
          return;
        }
        setState(() {
          _isSubmitting = false;
          _entered = '';
          _errorText = 'رمز PIN غير صحيح.';
        });
        return;
      case _PinMode.loading:
        return;
    }
  }

  String get _title => switch (_mode) {
        _PinMode.loading => '',
        _PinMode.create => 'أنشئ رمز PIN',
        _PinMode.confirm => 'أعد إدخال الرمز للتأكيد',
        _PinMode.verify => 'أدخل رمز PIN',
      };

  @override
  Widget build(BuildContext context) {
    if (_mode == _PinMode.loading) {
      return const FullScreenLoadingIndicator();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AvahiSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_title, style: context.textTheme.titleLarge),
                const SizedBox(height: AvahiSpacing.lg),
                _PinDots(filled: _entered.length, total: AppConstants.pinLength),
                const SizedBox(height: AvahiSpacing.sm),
                SizedBox(
                  height: 24,
                  child: _errorText != null
                      ? Text(
                          _errorText!,
                          style: TextStyle(color: context.colors.error),
                        )
                      : null,
                ),
                const SizedBox(height: AvahiSpacing.lg),
                PinKeypad(
                  enabled: !_isSubmitting,
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                ),
                const SizedBox(height: AvahiSpacing.lg),
                AvahiButton(
                  label: 'تسجيل الدخول بحساب آخر',
                  variant: AvahiButtonVariant.text,
                  // تسجيل خروج كامل عمداً (وليس تنقّل مباشر إلى
                  // `/login`): [AuthGuard] يمنع أصلاً وصول مستخدم لا
                  // تزال جلسته نشطة لشاشة الدخول (انظر
                  // `guards/auth_guard.dart`)، فتنقّل مباشر بلا تسجيل
                  // خروج فعلي سيُعاد توجيهه فوراً إلى `/home` من جديد.
                  onPressed: _isSubmitting
                      ? null
                      : () => context.read<AuthCubit>().logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AvahiSpacing.xxs),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled
                  ? context.colors.primary
                  : context.colors.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}
