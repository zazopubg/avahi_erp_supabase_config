/// شاشات مؤقتة متبقية فقط لوجهات `AdaptiveShell` التي لم تُبنَ بعد.
///
/// ⚠️ تحديث Prompt 13: شاشات تدفّق الدخول الأربع
/// (`SplashScreen`/`LoginScreen`/`PinScreen`/`CompanySelectScreen`)
/// انتقلت من هنا إلى تنفيذها الحقيقي في `features/auth/auth_feature.dart`
/// وأُزيلت من هذا الملف — `app_router.dart` يستوردها من هناك مباشرة
/// الآن. يبقى هنا فقط:
/// - [ComingSoonScreen] (تُستخدم لكل وجهات `AdaptiveShell` الأخرى) →
///   كل ميزة تستبدلها بشاشتها الفعلية بدءاً من `features/home/`
///   (Prompt 14) ثم بقية `features/` تباعاً.
/// - [HomePlaceholderScreen] → شاشة رئيسية مؤقتة مخصصة، تُستبدل عند
///   بناء `features/home/` (Prompt 14).
///
/// الاستبدال يتم فقط بتعديل `builder:` المسار المعني ضمن
/// `app_router.dart` — لا حاجة لأي تعديل على `guards/` أو `shells/`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/auth_feature.dart';
import '../ui/widgets/common/avahi_button.dart';
import '../ui/widgets/common/empty_state.dart';

/// شاشة عامة "قيد الإنشاء" تُستخدم مؤقتاً لكل وجهات `AdaptiveShell`
/// (باستثناء `home` التي لها شاشة مخصصة أدناه) بانتظار بناء ميزتها
/// الفعلية ضمن `features/`. تعرض [title] الوجهة نفسها حتى يبقى واضحاً
/// أي مسار قيد الاختبار أثناء التنقل بين القوالب.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        title: title,
        message: 'هذه الميزة قيد البناء ضمن خطوات لاحقة من المشروع.',
        icon: Icons.construction_outlined,
      ),
    );
  }
}

/// شاشة الرئيسية المؤقتة — نسخة خاصة من [ComingSoonScreen] تضيف زر
/// تسجيل خروج مباشراً، مفيدة لاختبار [AuthGuard] والانتقال العكسي إلى
/// `/login` عند إنهاء الجلسة، قبل وجود `features/home/` الفعلية
/// (Prompt 14) أو أي واجهة إعدادات/حساب حقيقية.
///
/// ⚠️ تحديث Prompt 13: تسجيل الخروج يمر الآن عبر `AuthCubit.logout()`
/// (وليس `sl<LogoutUsecase>()()` مباشرة كما في Prompt 12) — `AuthCubit`
/// يتكفّل أيضاً بمسح `SessionService` كاملاً (توكنات + رمز PIN المحلي)
/// وليس فقط إنهاء الجلسة السحابية.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أفاهي')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'الشاشة الرئيسية\n(سيتم بناؤها في features/home/)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              AvahiButton(
                label: 'تسجيل الخروج',
                variant: AvahiButtonVariant.danger,
                // لا حاجة لتنقّل يدوي هنا: `refreshListenable` في
                // `app_router.dart` يستمع لـ `watchAuthState()` وسيُعيد
                // تقييم [AuthGuard] تلقائياً فور تغيّر حالة المصادقة،
                // فيُعاد التوجيه إلى `/login` من تلقاء نفسه.
                onPressed: () => context.read<AuthCubit>().logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
