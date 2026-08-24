import 'package:image_picker/image_picker.dart';

import '../errors/failure.dart';
import '../errors/permission_exception.dart';
import 'camera_service.dart';

/// تنفيذ [CameraService] فوق حزمة `image_picker` — أول تنفيذ فعلي لهذا
/// العقد (كان `abstract class` بلا تنفيذ منذ Prompt 02)، مبني عند أول
/// حاجة فعلية له من `features/field_reports/` (Prompt 17،
/// `report_photo_attach.dart`) وسيُعاد استخدامه لاحقاً دون أي تعديل من
/// `features/photos/` (Prompt 18).
///
/// يعمل على الويب عبر واجهة اختيار/التقاط ملفات المتصفح القياسية التي
/// توفّرها `image_picker` نفسها (`ImageSource.camera` يفتح واجهة
/// التقاط الكاميرا المدعومة من المتصفح/الجهاز عند توفرها، ويتراجع
/// تلقائياً لمنتقي الملفات العادي حين لا تتوفر كاميرا).
class ImagePickerCameraService implements CameraService {
  ImagePickerCameraService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxDimension = 2048;
  static const int _imageQuality = 85;

  @override
  Future<ResultOf<CapturedImage?>> captureFromCamera() =>
      _pickSingle(ImageSource.camera);

  @override
  Future<ResultOf<CapturedImage?>> pickFromGallery() =>
      _pickSingle(ImageSource.gallery);

  @override
  Future<ResultOf<List<CapturedImage>>> pickMultipleFromGallery() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _imageQuality,
      );
      final List<CapturedImage> images = <CapturedImage>[];
      for (final XFile file in files) {
        images.add(await _toCapturedImage(file));
      }
      return Right<Failure, List<CapturedImage>>(images);
    } catch (error, stackTrace) {
      return Left<Failure, List<CapturedImage>>(
        Failure.fromException(
          PermissionException.denied(cause: error, st: stackTrace),
        ),
      );
    }
  }

  Future<ResultOf<CapturedImage?>> _pickSingle(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _imageQuality,
      );
      if (file == null) return const Right<Failure, CapturedImage?>(null);
      return Right<Failure, CapturedImage?>(await _toCapturedImage(file));
    } catch (error, stackTrace) {
      return Left<Failure, CapturedImage?>(
        Failure.fromException(
          PermissionException.denied(cause: error, st: stackTrace),
        ),
      );
    }
  }

  Future<CapturedImage> _toCapturedImage(XFile file) async {
    return CapturedImage(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType ?? 'image/jpeg',
    );
  }
}
