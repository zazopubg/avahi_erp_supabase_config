import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/widgets/common/loading_indicator.dart';
import '../state/auth_cubit.dart';

/// شاشة انتقالية عند المسار الجذري (`/`) — تستدعي
/// `AuthCubit.checkAuthStatus` مرة واحدة عند الدخول ثم تترك
/// `AuthGuard`/`app_router.dart` يحسمان الوجهة الفعلية (`/login` أو
/// `/home` أو `/company-select`) تلقائياً عبر `refreshListenable`
/// (`watchAuthState`) فور صدور [AuthState] جديدة — لا تنقّل يدوي هنا.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // بعد أول إطار لضمان جاهزية `BuildContext`/`BlocProvider` كاملة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const FullScreenLoadingIndicator();
  }
}
