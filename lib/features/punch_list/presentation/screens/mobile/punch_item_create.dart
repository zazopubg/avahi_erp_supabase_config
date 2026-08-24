import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/camera_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/punch_item.dart';
import '../../../../../domain/enums/task_priority.dart';
import '../../../../../ui/theme/avahi_radius.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/punch_cubit.dart';
import '../../state/punch_state.dart';
import '../../widgets/task_priority_selector_items.dart';

/// نقطة الدخول المستقلة لمسار `RouteNames.punchListCreate`
/// (`/punch-list/create`) — نسخة [PunchCubit] خاصة بها تماماً عبر
/// `sl<PunchCubit>()..loadInitial(user)`، بنفس منطق `TasksBoardScreen`
/// (`features/tasks/presentation/screens/desktop/tasks_board_screen.dart`):
/// يُفتح هذا المسار مباشرة إما من زر "+" داخل `punch_list_screen.dart`
/// أو من الإجراء السريع "تسجيل عيب" في `quick_actions.dart` (الصفحة
/// الرئيسية) دون المرور بـ `/punch-list` إطلاقاً؛ لذا لا يعتمد على أي
/// `PunchCubit` مزوَّد مسبقاً من شجرة أعلى.
///
/// ⚠️ نتيجة قصديّة لهذا الاستقلال: نجاح الإنشاء هنا لا يُحدّث فوراً
/// قائمة `/punch-list` إن كانت مفتوحة أصلاً خلف هذه الشاشة (نسخة
/// `PunchCubit` مختلفة) — `punch_list_screen.dart` يستدعي
/// `PunchCubit.refresh()` بعد العودة من هذا المسار تحديداً لتعويض ذلك
/// (`context.pushNamed(...).then((_) => ...refresh())`), بنفس القيد
/// المقبول أصلاً في `TasksBoardScreen`/`TasksScreen`.
class PunchItemCreateScreen extends StatelessWidget {
  const PunchItemCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<PunchCubit>(
              create: (_) => sl<PunchCubit>()..loadInitial(user),
              child: const _PunchItemCreateBody(),
            );
          },
        );
      },
    );
  }
}

class _PunchItemCreateBody extends StatefulWidget {
  const _PunchItemCreateBody();

  @override
  State<_PunchItemCreateBody> createState() => _PunchItemCreateBodyState();
}

class _PunchItemCreateBodyState extends State<_PunchItemCreateBody> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationNoteController =
      TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  GeoPoint? _capturedLocation;
  bool _isCapturingLocation = false;
  final List<CapturedImage> _photos = <CapturedImage>[];

  @override
  void initState() {
    super.initState();
    // التقاط الموقع تلقائياً عند فتح النموذج — بصمت عند الفشل (إذن
    // مرفوض، أو جهاز بلا GPS على سطح المكتب)، انظر توثيق
    // `PunchCubit.captureCurrentLocation`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLocation());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNoteController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    final GeoPoint? point = await context.read<PunchCubit>().captureCurrentLocation();
    if (!mounted) return;
    setState(() {
      _capturedLocation = point;
      _isCapturingLocation = false;
    });
  }

  Future<void> _addPhoto({required bool fromCamera}) async {
    final CapturedImage? image = await context.read<PunchCubit>().captureImage(
          fromCamera: fromCamera,
        );
    if (image == null) return;
    setState(() => _photos.add(image));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final PunchItem? created = await context.read<PunchCubit>().createPunchItem(
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          locationNote: _locationNoteController.text,
          location: _capturedLocation,
          photos: _photos,
        );

    if (!mounted) return;
    if (created == null) {
      context.showSnackBar('تعذّر تسجيل العيب، حاول مجدداً.');
      return;
    }
    context.showSnackBar('سُجِّل العيب بنجاح.');
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (BuildContext context, PunchState state) {
        final PunchData? data = state.dataOrNull;
        final bool hasProject = data?.project != null;
        final bool isSubmitting = data?.isSubmitting ?? false;

        return Scaffold(
          appBar: AppBar(title: const Text('تسجيل عيب / ملاحظة')),
          body: state is PunchLoading
              ? const LoadingIndicator()
              : !hasProject
                  ? const Padding(
                      padding: EdgeInsets.all(AvahiSpacing.xl),
                      child: Center(
                        child: Text('لا يوجد مشروع نشط مرتبط بحسابك حالياً.'),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AvahiSpacing.md),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AvahiTextField(
                              controller: _titleController,
                              label: 'عنوان الملاحظة',
                              hint: 'مثال: تشقق في جدار الطابق الثاني',
                              enabled: !isSubmitting,
                              validator: (String? value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'العنوان إلزامي.'
                                      : null,
                            ),
                            const SizedBox(height: AvahiSpacing.md),
                            AvahiTextField(
                              controller: _descriptionController,
                              label: 'الوصف (اختياري)',
                              hint: 'تفاصيل إضافية عن العيب...',
                              maxLines: 4,
                              enabled: !isSubmitting,
                            ),
                            const SizedBox(height: AvahiSpacing.md),
                            AvahiDropdown<TaskPriority>(
                              label: 'الأولوية',
                              value: _priority,
                              items: kTaskPriorityDropdownItems,
                              enabled: !isSubmitting,
                              onChanged: (TaskPriority? value) {
                                if (value != null) {
                                  setState(() => _priority = value);
                                }
                              },
                            ),
                            const SizedBox(height: AvahiSpacing.md),
                            AvahiTextField(
                              controller: _locationNoteController,
                              label: 'ملاحظة الموقع (اختياري)',
                              hint: 'مثال: بجانب المصعد، الطابق 3',
                              prefixIcon: Icons.place_outlined,
                              enabled: !isSubmitting,
                            ),
                            const SizedBox(height: AvahiSpacing.xs),
                            _LocationCaptureStatus(
                              isCapturing: _isCapturingLocation,
                              location: _capturedLocation,
                              onRetry: _captureLocation,
                            ),
                            const SizedBox(height: AvahiSpacing.lg),
                            Text(
                              'صور مرفقة (اختياري)',
                              style: context.textTheme.titleSmall,
                            ),
                            const SizedBox(height: AvahiSpacing.xs),
                            _PhotoPickerRow(
                              photos: _photos,
                              enabled: !isSubmitting,
                              onAddCamera: () => _addPhoto(fromCamera: true),
                              onAddGallery: () => _addPhoto(fromCamera: false),
                              onRemove: (int index) =>
                                  setState(() => _photos.removeAt(index)),
                            ),
                            const SizedBox(height: AvahiSpacing.xl),
                            AvahiButton(
                              label: 'تسجيل العيب',
                              icon: Icons.add_task,
                              isFullWidth: true,
                              isLoading: isSubmitting,
                              onPressed: isSubmitting ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }
}

class _LocationCaptureStatus extends StatelessWidget {
  const _LocationCaptureStatus({
    required this.isCapturing,
    required this.location,
    required this.onRetry,
  });

  final bool isCapturing;
  final GeoPoint? location;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isCapturing) {
      return Row(
        children: <Widget>[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AvahiSpacing.xs),
          Text(
            'جارٍ تحديد الموقع الحالي...',
            style: context.textTheme.labelSmall,
          ),
        ],
      );
    }

    if (location == null) {
      return TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.gps_fixed, size: 16),
        label: const Text('إعادة محاولة تحديد الموقع'),
      );
    }

    return Row(
      children: <Widget>[
        Icon(Icons.gps_fixed, size: 16, color: context.colors.primary),
        const SizedBox(width: AvahiSpacing.xs),
        Expanded(
          child: Text(
            'تم تحديد الموقع: ${location!.latitude.toStringAsFixed(5)}, '
            '${location!.longitude.toStringAsFixed(5)}',
            style: context.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _PhotoPickerRow extends StatelessWidget {
  const _PhotoPickerRow({
    required this.photos,
    required this.enabled,
    required this.onAddCamera,
    required this.onAddGallery,
    required this.onRemove,
  });

  final List<CapturedImage> photos;
  final bool enabled;
  final VoidCallback onAddCamera;
  final VoidCallback onAddGallery;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AvahiSpacing.sm,
      runSpacing: AvahiSpacing.sm,
      children: <Widget>[
        for (int i = 0; i < photos.length; i++)
          Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: AvahiRadius.radiusMd,
                child: Image.memory(
                  photos[i].bytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  icon: const Icon(Icons.cancel, size: 18),
                  onPressed: enabled ? () => onRemove(i) : null,
                ),
              ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: enabled ? onAddCamera : null,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: const Text('كاميرا'),
        ),
        OutlinedButton.icon(
          onPressed: enabled ? onAddGallery : null,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('معرض'),
        ),
      ],
    );
  }
}
