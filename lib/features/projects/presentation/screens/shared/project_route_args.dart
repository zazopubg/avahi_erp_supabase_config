import '../../state/projects_cubit.dart';

/// حزمة وسيطة (Args) تُمرَّر عبر `extra:` لمسارات `/projects/:id`،
/// `/projects/:id/members`، `/projects/:id/milestones` — تحمل معرّف
/// المشروع (`:id` نفسه، مطابقةً له دائماً) **و**نسخة [ProjectsCubit]
/// الحيّة نفسها التي فتحت الشاشة (من `my_projects_screen.dart` أو
/// `projects_list.dart`)، بنفس نمط `PunchItemDetailsRouteArgs`
/// (`features/punch_list/`) تماماً — يضمن أن أي تعديل (عضو مُضاف،
/// مرحلة مُحدَّثة...) داخل هذه الشاشات الفرعية ينعكس فوراً على نفس
/// القائمة خلفها عند العودة إليها.
///
/// ⚠️ [projectId] لا [Project] الكامل عمداً (بخلاف
/// `PunchItemDetailsRouteArgs.item`): [ProjectsCubit.selectProject]
/// يُستدعى دائماً *قبل* الدفع بهذا المسار (من `_openProject` في كل من
/// `my_projects_screen.dart`/`projects_list.dart`)، لذا `selectedProject`
/// ضمن [ProjectsCubit] نفسه هو مصدر الحقيقة الفعلي — [projectId] هنا
/// يُستخدم فقط للتحقق (`assert`) ولإعادة التحميل عند التنقّل المباشر
/// (Deep Link) لأي من المسارات الثلاثة.
class ProjectRouteArgs {
  const ProjectRouteArgs({required this.projectId, required this.cubit});

  final String projectId;
  final ProjectsCubit cubit;
}
