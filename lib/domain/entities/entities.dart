/// ملف تجميعي (Barrel File) لكل كيانات طبقة الـ domain، لتسهيل
/// الاستيراد من طبقتي `data/` و`presentation/` عبر سطر واحد:
/// `import 'package:avahi/domain/entities/entities.dart';`
library;

export 'app_notification.dart';
export 'app_user.dart';
export 'attendance_record.dart';
export 'audit_log.dart';
export 'blueprint.dart';
export 'company.dart';
export 'document.dart';
export 'equipment.dart';
export 'field_report.dart';
export 'leave_request.dart';
export 'project.dart';
export 'project_member.dart';
export 'project_member_detail.dart';
export 'project_milestone.dart';
export 'punch_item.dart';
export 'site_photo.dart';
export 'task.dart';
