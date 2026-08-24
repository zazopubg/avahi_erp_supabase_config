/// ملف تجميعي (Barrel File) لميزة `features/leave_requests/` كاملة —
/// يسمح لـ `navigation/app_router.dart` وأي طبقة أخرى باستيراد كل
/// شاشات وحالة هذه الميزة عبر سطر واحد، بنفس نمط
/// `features/punch_list/punch_list_feature.dart`/
/// `features/equipment/equipment_feature.dart` تماماً. 🆕 (Prompt 24)
///
/// ⚠️ ملاحظة نطاق: هذه الميزة تصدّر شاشة **واحدة فقط** يستهلكها
/// `app_router.dart` مباشرة كنقطة `go_router` — [MyLeaveRequestsScreen]
/// (`/leave-requests`، تُفوِّض داخلياً لـ [LeaveRequestsInbox] على
/// سطح المكتب لمن يملك صلاحية الاعتماد، ولـ
/// [CreateLeaveRequestScreen] عبر `Navigator.push` عادي، بلا مسار
/// `go_router` منفصل لأيّهما) — بنفس منطق `PunchListScreen` (التزاماً
/// حرفياً بشجرة Prompt 24 المرفقة، التي لا تذكر ملف
/// `leave_requests_screen.dart` جذر منفصل)؛ انظر توثيق القرار الكامل
/// في `MyLeaveRequestsScreen`. [LeaveRequestsInbox]/
/// [CreateLeaveRequestScreen]/[LeaveRequestReview] داخلية بالكامل
/// (يستهلكها [MyLeaveRequestsScreen]/[LeaveRequestsInbox] نفسهما حسب
/// `ShellMode`) لكنها مُصدَّرة أيضاً لتسهيل اختبارها بمعزل لاحقاً في
/// `test/` (Prompt 29).
library;

export 'presentation/screens/desktop/leave_request_review.dart';
export 'presentation/screens/desktop/leave_requests_inbox.dart';
export 'presentation/screens/mobile/create_leave_request_screen.dart';
export 'presentation/screens/mobile/my_leave_requests_screen.dart';
export 'presentation/state/leave_cubit.dart';
export 'presentation/state/leave_state.dart';
export 'presentation/widgets/date_range_picker_field.dart';
export 'presentation/widgets/leave_approval_actions.dart';
export 'presentation/widgets/leave_request_card.dart';
export 'presentation/widgets/leave_status_badge.dart';
export 'presentation/widgets/leave_type_selector_items.dart';
