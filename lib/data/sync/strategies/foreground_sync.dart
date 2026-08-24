import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/utils/logger.dart';
import 'sync_strategy.dart';

/// استراتيجية المزامنة الفورية عند استعادة تركيز التطبيق/تبويب
/// المتصفح — مكمِّلة لـ [ContinuousSyncStrategy] (لا تُغني عنها):
/// تلتقط اللحظة الأكثر احتمالاً لوجود بيانات معلّقة تستحق الإرسال فوراً
/// (مثال: المستخدم فتح تطبيقاً آخر لبضع دقائق ثم عاد للتبويب) بدل
/// انتظار الدورة الثابتة التالية.
///
/// المشروع مستهدَف حصراً لمنصة الويب (Chrome) في هذه المرحلة (انظر
/// ملاحظة `pubspec.yaml`)، حيث يُترجم Flutter Web أحداث Page
/// Visibility API الخاصة بالمتصفح (`document.visibilityState`) مباشرة
/// إلى دورة حياة `WidgetsBindingObserver` القياسية:
/// [AppLifecycleState.resumed] عند عودة التبويب للواجهة،
/// [AppLifecycleState.hidden]/[AppLifecycleState.inactive] عند مغادرته
/// — لذا لا حاجة لأي استدعاء JS Interop خام (`dart:js_interop`) مباشر
/// هنا؛ الاعتماد على واجهة Flutter القياسية يبقيها متوافقة أيضاً لو
/// امتد التطبيق لاحقاً لمنصات أخرى (جوال/سطح مكتب) دون أي تعديل.
class ForegroundSyncStrategy with WidgetsBindingObserver implements SyncStrategy {
  Future<void> Function()? _onTrigger;
  bool _active = false;

  @override
  void start(Future<void> Function() onTrigger) {
    _onTrigger = onTrigger;
    if (!_active) {
      WidgetsBinding.instance.addObserver(this);
      _active = true;
      AppLogger.debug(
        'ForegroundSyncStrategy: بدأت مراقبة استعادة تركيز التطبيق.',
      );
    }
  }

  @override
  void stop() {
    if (_active) {
      WidgetsBinding.instance.removeObserver(this);
      _active = false;
    }
  }

  @override
  bool get isActive => _active;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    AppLogger.debug(
      'ForegroundSyncStrategy: استعاد التبويب/التطبيق التركيز — '
      'تشغيل مزامنة فورية.',
    );
    unawaited(_safeTrigger());
  }

  Future<void> _safeTrigger() async {
    try {
      await _onTrigger?.call();
    } catch (error, stackTrace) {
      AppLogger.error(
        'ForegroundSyncStrategy: فشل تشغيل دورة المزامنة عند استعادة التركيز.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
