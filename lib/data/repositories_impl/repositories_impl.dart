/// ملف تجميعي (Barrel File) لكل `*RepositoryImpl` في
/// `data/repositories_impl/` — التنفيذات **النهائية** التي تُحقن فعلياً
/// في `domain/usecases/` عبر `core/di/` (Prompt 11)، وليست تلك تحت
/// `data/cloud/supabase/repositories/` (Prompt 07) التي أصبحت الآن
/// تفاصيل داخلية يُستدعى بعضها من هنا مباشرة (الحضور/الإشعارات) أو
/// عبر `sync_engine` فقط (البقية).
///
/// `import 'package:avahi/data/repositories_impl/repositories_impl.dart';`
library;

export 'attendance_repository_impl.dart';
export 'equipment_repository_impl.dart';
export 'leave_repository_impl.dart';
export 'notification_repository_impl.dart';
export 'report_repository_impl.dart';
export 'task_repository_impl.dart';
