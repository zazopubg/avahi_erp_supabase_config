import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/camera_service.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/punch_item.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';
import '../state/punch_cubit.dart';
import '../state/punch_state.dart';

/// نموذج الإغلاق الرسمي لعنصر ملاحظات — ملاحظة معالجة نصية إلزامية +
/// صورة معالجة (بعد الإصلاح) إلزامية أيضاً، معاً عبر
/// `PunchCubit.closePunchItemWithEvidence` (انظر توثيق القرار الكامل
/// حول تخزين نص الملاحظة كـ `SitePhoto.caption` أعلى `punch_cubit.dart`).
///
/// مكوّن مُستخدَم من كلا الطرفين اللذين يملكان [Permission.punchListCloseOut]:
/// `punch_item_manage.dart` (سطح المكتب، ضمن لوحة الإدارة مباشرة) و
/// `punch_item_details.dart` (الهاتف، عبر [show] كـ Bottom Sheet).
class PunchCloseForm extends StatefulWidget {
  const PunchCloseForm({required this.item, super.key, this.onClosed});

  final PunchItem item;

  /// يُستدعى بعد نجاح الإغلاق فعلياً — الشاشة الأب تستخدمه لإغلاق أي
  /// حوار/لوحة مفتوحة أو تحديث تنقّلها.
  final VoidCallback? onClosed;

  /// طريقة مختصرة لعرض النموذج كـ Bottom Sheet قابل للتمرير (مناسب
  /// للهاتف عندما لا تتوفر مساحة لوحة جانبية ثابتة كسطح المكتب).
  static Future<void> show(
    BuildContext context, {
    required PunchItem item,
    VoidCallback? onClosed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: PunchCloseForm(item: item, onClosed: onClosed),
      ),
    );
  }

  @override
  State<PunchCloseForm> createState() => _PunchCloseFormState();
}

class _PunchCloseFormState extends State<PunchCloseForm> {
  final TextEditingController _noteController = TextEditingController();
  CapturedImage? _evidence;
  String? _validationError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidence({required bool fromCamera}) async {
    final CapturedImage? image = await context.read<PunchCubit>().captureImage(
          fromCamera: fromCamera,
        );
    if (image == null) return;
    setState(() {
      _evidence = image;
      _validationError = null;
    });
  }

  Future<void> _submit() async {
    final String note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _validationError = 'ملاحظة المعالجة إلزامية قبل الإغلاق.');
      return;
    }
    if (_evidence == null) {
      setState(
        () => _validationError = 'يجب إرفاق صورة معالجة بعد الإصلاح للإغلاق.',
      );
      return;
    }

    final bool success = await context.read<PunchCubit>().closePunchItemWithEvidence(
          item: widget.item,
          note: note,
          evidence: _evidence!,
        );

    if (!mounted) return;
    if (!success) {
      setState(() => _validationError = 'تعذّر إغلاق عنصر الملاحظات، حاول مجدداً.');
      return;
    }

    context.showSnackBar('أُغلق عنصر الملاحظات بنجاح.');
    widget.onClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (BuildContext context, PunchState state) {
        final bool isClosing = state.dataOrNull?.isClosing ?? false;

        return Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('إغلاق عنصر الملاحظات', style: context.textTheme.titleMedium),
              const SizedBox(height: AvahiSpacing.xs),
              Text(
                widget.item.title,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AvahiSpacing.md),
              AvahiTextField(
                controller: _noteController,
                label: 'ملاحظة المعالجة',
                hint: 'صف الإصلاح المُنجَز فعلياً...',
                maxLines: 3,
                enabled: !isClosing,
              ),
              const SizedBox(height: AvahiSpacing.md),
              Text('صورة المعالجة', style: context.textTheme.titleSmall),
              const SizedBox(height: AvahiSpacing.xs),
              _EvidencePreview(
                evidence: _evidence,
                enabled: !isClosing,
                onCamera: () => _captureEvidence(fromCamera: true),
                onGallery: () => _captureEvidence(fromCamera: false),
              ),
              if (_validationError != null) ...<Widget>[
                const SizedBox(height: AvahiSpacing.sm),
                Text(
                  _validationError!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
              const SizedBox(height: AvahiSpacing.lg),
              AvahiButton(
                label: 'تأكيد الإغلاق',
                icon: Icons.check_circle_outline,
                isFullWidth: true,
                isLoading: isClosing,
                onPressed: isClosing ? null : _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EvidencePreview extends StatelessWidget {
  const _EvidencePreview({
    required this.evidence,
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
  });

  final CapturedImage? evidence;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        if (evidence != null)
          ClipRRect(
            borderRadius: AvahiRadius.radiusMd,
            child: Image.memory(
              evidence!.bytes,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: AvahiRadius.radiusMd,
            ),
            child: Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
          ),
        const SizedBox(width: AvahiSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AvahiSpacing.xs,
            runSpacing: AvahiSpacing.xs,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: enabled ? onCamera : null,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('كاميرا'),
              ),
              OutlinedButton.icon(
                onPressed: enabled ? onGallery : null,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('معرض'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
