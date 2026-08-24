import 'dart:async';

import '../../../core/utils/logger.dart';
import 'sync_strategy.dart';

/// استراتيجية المزامنة الدورية المستمرة: تُشغِّل دورة مزامنة كل
/// [interval] ثابتة طوال عمر التطبيق (طالما التطبيق مفتوحاً)، بصرف
/// النظر عن أي أحداث أخرى — خط الدفاع الأساسي الذي يضمن عدم بقاء أي
/// عملية معلّقة في `local_outbox` لفترة طويلة حتى لو لم يتفاعل
/// المستخدم مع التطبيق أو يبدّل تبويبات المتصفح.
///
/// ⚠️ الفترة الافتراضية هنا 30 ثانية (كما هو منصوص عليه لهذه الخطوة).
/// طبقة الحقن (`core/di/`، Prompt 11) قد تُمرِّر بدلاً منها
/// `AppConfig.instance.syncInterval` (المعتمدة على البيئة: دقيقة واحدة
/// في `dev`، 3 دقائق في `staging`، 5 دقائق في `prod` — انظر
/// `core/config/app_config.dart`) لتقليل الحمل على الخادم في الإنتاج
/// دون تغيير هذا الملف.
class ContinuousSyncStrategy implements SyncStrategy {
  ContinuousSyncStrategy({this.interval = const Duration(seconds: 30)});

  final Duration interval;

  Timer? _timer;
  Future<void> Function()? _onTrigger;

  @override
  void start(Future<void> Function() onTrigger) {
    _onTrigger = onTrigger;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _safeTrigger());
    AppLogger.debug(
      'ContinuousSyncStrategy: بدأت المزامنة الدورية كل ${interval.inSeconds}ث.',
    );
  }

  Future<void> _safeTrigger() async {
    try {
      await _onTrigger?.call();
    } catch (error, stackTrace) {
      // فشل دورة كاملة يجب ألا يوقف المؤقّت نفسه — الدورة التالية
      // ستُحاول من جديد تلقائياً.
      AppLogger.error(
        'ContinuousSyncStrategy: فشل تشغيل دورة مزامنة دورية.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  bool get isActive => _timer?.isActive ?? false;
}
