/// ملف تجميعي (Barrel File) لكل `*RepositoryImpl` في
/// `data/cloud/supabase/repositories/`. ⚠️ هذه التنفيذات "سحابية
/// خالصة" (Cloud-only) تفترض اتصالاً دائماً بالإنترنت ولا تحوي أي
/// منطق Offline — الدمج مع `data/local/` (Drift، Prompt 08) ضمن
/// مستودع مُوحَّد سيتم في `data/repositories_impl/` (Prompt 10)، والتي
/// ستُطبّق واجهات `domain/repositories/` نفسها وتُفوِّض إليها هذه
/// الملفات داخلياً بدل استبدالها.
library;

export 'attendance_repository_impl.dart';
export 'auth_repository_impl.dart';
export 'company_repository_impl.dart';
export 'document_repository_impl.dart';
export 'equipment_repository_impl.dart';
export 'leave_repository_impl.dart';
export 'notification_repository_impl.dart';
export 'photo_repository_impl.dart';
export 'platform_admin_repository_impl.dart';
export 'project_repository_impl.dart';
export 'punch_repository_impl.dart';
export 'report_repository_impl.dart';
export 'task_repository_impl.dart';
export 'user_repository_impl.dart';
