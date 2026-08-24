import 'app_exception.dart';
import 'auth_exception.dart';
import 'network_exception.dart';
import 'permission_exception.dart';
import 'sync_exception.dart';

/// تمثيل خفيف وقابل للمقارنة (Value Type) لفشل عملية، مخصص للتنقّل
/// بين طبقات `domain`/`data` دون تسريب تفاصيل استثناء Dart خام إلى
/// طبقة العرض (Presentation). كل [AppException] يُترجَم إلى [Failure]
/// مطابق عبر [Failure.fromException] عند حدوده مع طبقة Data.
sealed class Failure {
  const Failure({required this.message, required this.code});

  final String message;
  final String code;

  /// يحوّل أي [AppException] ملتقط إلى [Failure] مناسب. أي استثناء
  /// غير معروف يُغلَّف كـ [UnknownFailure] بدلاً من رميه من جديد.
  factory Failure.fromException(Object error) {
    if (error is NetworkException) {
      return NetworkFailure(message: error.message, code: error.code);
    }
    if (error is AuthException) {
      return AuthFailure(message: error.message, code: error.code);
    }
    if (error is PermissionException) {
      return PermissionFailure(message: error.message, code: error.code);
    }
    if (error is SyncException) {
      return SyncFailure(message: error.message, code: error.code);
    }
    if (error is AppException) {
      return UnknownFailure(message: error.message, code: error.code);
    }
    return UnknownFailure(message: error.toString(), code: 'app.unknown');
  }

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, required super.code});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, required super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, required super.code});
}

class SyncFailure extends Failure {
  const SyncFailure({required super.message, required super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    required super.code,
    this.fieldErrors = const <String, String>{},
  });

  final Map<String, String> fieldErrors;
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, required super.code});
}

/// نوع Either خفيف الوزن مخصص للمشروع (بدون اعتماد على حزمة خارجية
/// مثل `dartz`)، يمثل إما فشلاً [Failure] (Left) أو نجاحاً بقيمة من
/// النوع [T] (Right). يُستخدم كنوع إرجاع موحّد لكل استدعاءات
/// `domain/usecases/` و`domain/repositories/` بدءاً من Prompt 06.
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  /// يستدعي [onLeft] أو [onRight] حسب حالة القيمة الحالية، ويُعيد
  /// نتيجة موحّدة من النوع [T] — نمط مطابقة الأنماط الآمن (Fold).
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    final Either<L, R> self = this;
    if (self is Left<L, R>) return onLeft(self.value);
    if (self is Right<L, R>) return onRight(self.value);
    throw StateError('Either غير متوقع: لا Left ولا Right.');
  }

  /// يحوّل قيمة [Right] عبر [mapper] مع الحفاظ على [Left] كما هي.
  Either<L, T> map<T>(T Function(R right) mapper) {
    final Either<L, R> self = this;
    if (self is Right<L, R>) return Right<L, T>(mapper(self.value));
    return Left<L, T>((self as Left<L, R>).value);
  }

  R? getOrNull() {
    final Either<L, R> self = this;
    return self is Right<L, R> ? self.value : null;
  }
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
}

/// اختصار شائع الاستخدام في هذا المشروع: نتيجة عملية إما [Failure]
/// أو قيمة ناجحة من النوع [T].
typedef ResultOf<T> = Either<Failure, T>;
