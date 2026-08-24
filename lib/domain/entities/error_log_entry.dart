import 'package:equatable/equatable.dart';

/// شدة سجل خطأ واحد ضمن `error_logs.dart`.
enum ErrorLogSeverity {
  info,
  warning,
  error,
  critical;

  bool get isCritical => this == ErrorLogSeverity.critical;
}

/// سجل خطأ تشغيلي واحد على مستوى المنصّة (عابر للمستأجرين)، يُعرَض في
/// `error_logs.dart` ضمن `lib/features/platform_admin/`. 🆕 (Prompt 28)
///
/// ⚠️ نفس قرار التصميم الموثَّق في [PlatformUsageSnapshot] (بيانات
/// تجريبية بالكامل — "بيانات تجريبية إن لم يوجد مصدر حقيقي بعد" مقرَّة
/// صراحة لـ `error_logs.dart` تحديداً ضمن سياق Prompt 28) — لا يوجد
/// بعد أي جدول `error_logs`/تكامل مع خدمة تتبّع أخطاء فعلية (Sentry
/// إلخ)؛ [companyId] وحده حقيقي دائماً (مُسحوب من قائمة الشركات
/// الفعلية عند توليد السجلات، وليس معرّفاً وهمياً).
class ErrorLogEntry extends Equatable {
  const ErrorLogEntry({
    required this.id,
    required this.severity,
    required this.source,
    required this.message,
    required this.occurredAt,
    required this.isResolved,
    this.companyId,
  });

  final String id;
  final ErrorLogSeverity severity;

  /// مصدر الخطأ (مثال: `edge-function:invite-user`، `client:sync-engine`).
  final String source;

  final String message;
  final DateTime occurredAt;
  final bool isResolved;

  /// الشركة المتأثرة، أو `null` لخطأ عام على مستوى المنصّة كاملة (لا
  /// يخص مستأجراً بعينه، مثال: فشل اتصال قاعدة بيانات عام).
  final String? companyId;

  ErrorLogEntry copyWith({
    String? id,
    ErrorLogSeverity? severity,
    String? source,
    String? message,
    DateTime? occurredAt,
    bool? isResolved,
    String? companyId,
  }) {
    return ErrorLogEntry(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      message: message ?? this.message,
      occurredAt: occurredAt ?? this.occurredAt,
      isResolved: isResolved ?? this.isResolved,
      companyId: companyId ?? this.companyId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        severity,
        source,
        message,
        occurredAt,
        isResolved,
        companyId,
      ];
}
