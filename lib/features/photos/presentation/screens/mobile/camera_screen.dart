import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/services/camera_service.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/photos_cubit.dart';
import 'photo_attach_screen.dart' show PhotoAttachRouteArgs;

/// شاشة الالتقاط — الخطوة الأولى من تدفّق إضافة صورة ميدانية جديدة
/// (`RoutePaths.photosCamera`، `/photos/camera`). تفتح كاميرا الجهاز
/// أو منتقي الملفات (`image_picker` — يدعم الويب/الديسكتاوب تلقائياً
/// عبر واجهة اختيار ملفات المتصفح عند عدم توفر كاميرا جهاز فعلية) فور
/// الدخول مباشرة، ثم تنتقل تلقائياً إلى `photo_attach_screen.dart`
/// (`RoutePaths.photosAttach`) مُمرِّرة الصورة الملتقطة الخام عبر
/// `extra` — لا ضغط ولا إدراج في الطابور بعد هنا (انظر توثيق القرار
/// الكامل في `PhotosCubit.captureImage`/`enqueueCapturedImage`).
///
/// مسار خارج `AdaptiveShell` عمداً (بنفس منطق `/login`) — تدفّق التقاط
/// صورة يحتاج شاشة كاملة بلا حواف تنقّل ثابتة تشتت الانتباه.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isPicking = true;
  bool _pickerFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCapture(fromCamera: true));
  }

  Future<void> _startCapture({required bool fromCamera}) async {
    if (!mounted) return;
    setState(() {
      _isPicking = true;
      _pickerFailed = false;
    });

    final PhotosCubit cubit = context.read<PhotosCubit>();
    final CapturedImage? captured = await cubit.captureImage(fromCamera: fromCamera);

    if (!mounted) return;

    if (captured == null) {
      setState(() {
        _isPicking = false;
        _pickerFailed = true;
      });
      return;
    }

    context.pushReplacementNamed(
      RouteNames.photosAttach,
      extra: PhotoAttachRouteArgs(cubit: cubit, captured: captured),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقاط صورة'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _isPicking
            ? const LoadingIndicator(label: 'جارٍ فتح الكاميرا...')
            : Padding(
                padding: const EdgeInsets.all(AvahiSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_pickerFailed) ...<Widget>[
                      const Icon(Icons.photo_camera_back_outlined, size: 48),
                      const SizedBox(height: AvahiSpacing.md),
                      const Text('لم يتم التقاط أي صورة.'),
                      const SizedBox(height: AvahiSpacing.lg),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AvahiButton(
                          label: 'الكاميرا',
                          icon: Icons.photo_camera_outlined,
                          onPressed: () => _startCapture(fromCamera: true),
                        ),
                        const SizedBox(width: AvahiSpacing.sm),
                        AvahiButton(
                          label: 'المعرض',
                          icon: Icons.photo_library_outlined,
                          variant: AvahiButtonVariant.secondary,
                          onPressed: () => _startCapture(fromCamera: false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
