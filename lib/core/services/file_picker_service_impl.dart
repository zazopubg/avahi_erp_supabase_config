import 'package:file_picker/file_picker.dart';

import '../errors/app_exception.dart';
import '../errors/failure.dart';
import 'file_picker_service.dart';

/// تنفيذ [FilePickerService] فوق حزمة `file_picker` — أول تنفيذ فعلي
/// لهذا العقد (كان `abstract class` بلا تنفيذ منذ Prompt 02)، مبني عند
/// أول حاجة فعلية له من `features/documents/` (Prompt 21،
/// `documents_manager.dart` — رفع مستندات من سطح المكتب فقط، انظر
/// توثيق القرار الكامل هناك حول كون `documents_list.dart` (الجوال)
/// عرضاً فقط بلا رفع).
///
/// يعمل على الويب عبر `withData: true` دائماً (يُرجع بايتات الملف
/// مباشرة ضمن `PlatformFile.bytes` بدل مسار على القرص، وهو الشكل
/// الوحيد المتاح فعلياً على الويب) — بخلاف `ImagePickerCameraService`
/// (`core/services/`، Prompt 17) التي تعتمد `XFile.readAsBytes()` بعد
/// الاختيار، هنا تُقرأ البايتات كجزء من استدعاء الاختيار نفسه لأن
/// `file_picker` (بخلاف `image_picker`) لا يوفر مساراً موحّداً لقراءة
/// البايتات لاحقاً على الويب تحديداً.
class FilePickerServiceImpl implements FilePickerService {
  const FilePickerServiceImpl();

  @override
  Future<ResultOf<PickedFile?>> pickSingle({
    List<String> allowedExtensions = const <String>[],
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
        withData: true,
      );

      final PlatformFile? file = result?.files.firstOrNull;
      if (file == null || file.bytes == null) {
        return const Right<Failure, PickedFile?>(null);
      }

      return Right<Failure, PickedFile?>(
        PickedFile(
          bytes: file.bytes!,
          fileName: file.name,
          sizeBytes: file.size,
        ),
      );
    } catch (error, stackTrace) {
      return Left<Failure, PickedFile?>(
        Failure.fromException(_mapError(error, stackTrace)),
      );
    }
  }

  @override
  Future<ResultOf<List<PickedFile>>> pickMultiple({
    List<String> allowedExtensions = const <String>[],
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
        withData: true,
        allowMultiple: true,
      );

      if (result == null) {
        return const Right<Failure, List<PickedFile>>(<PickedFile>[]);
      }

      final List<PickedFile> files = result.files
          .where((PlatformFile f) => f.bytes != null)
          .map(
            (PlatformFile f) => PickedFile(
              bytes: f.bytes!,
              fileName: f.name,
              sizeBytes: f.size,
            ),
          )
          .toList(growable: false);

      return Right<Failure, List<PickedFile>>(files);
    } catch (error, stackTrace) {
      return Left<Failure, List<PickedFile>>(
        Failure.fromException(_mapError(error, stackTrace)),
      );
    }
  }

  /// يغلّف أي استثناء غير متوقع من `file_picker` (رفض إذن، إلغاء غير
  /// قياسي...) ضمن [AppException] عام، بنفس نمط بقية خدمات `core/services/`
  /// التي لا تملك معالج أخطاء متخصصاً بها (بخلاف `SupabaseErrorMapper`
  /// المخصص لأخطاء الشبكة/الخادم فقط).
  AppException _mapError(Object error, StackTrace stackTrace) {
    if (error is AppException) return error;
    return UnexpectedAppException(
      message: 'تعذّر اختيار الملف: ${error.toString()}',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
