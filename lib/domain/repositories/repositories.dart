/// ملف تجميعي (Barrel File) لكل عقود المستودعات (Repository Interfaces)
/// في طبقة الـ domain، لتسهيل الاستيراد من طبقتي `data/` و`presentation/`
/// عبر سطر واحد: `import 'package:avahi/domain/repositories/repositories.dart';`
library;

export 'i_attendance_repository.dart';
export 'i_auth_repository.dart';
export 'i_company_repository.dart';
export 'i_document_repository.dart';
export 'i_equipment_repository.dart';
export 'i_leave_repository.dart';
export 'i_notification_repository.dart';
export 'i_photo_repository.dart';
export 'i_platform_admin_repository.dart';
export 'i_project_repository.dart';
export 'i_punch_repository.dart';
export 'i_report_repository.dart';
export 'i_task_repository.dart';
export 'i_user_repository.dart';
