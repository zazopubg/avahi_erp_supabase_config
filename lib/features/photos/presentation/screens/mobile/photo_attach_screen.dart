import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/services/camera_service.dart';
import '../../../../../domain/enums/related_entity_type.dart';
import '../../../../../navigation/route_paths.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../state/photos_cubit.dart';
import '../../state/photos_state.dart';
import '../../widgets/photo_tag_selector.dart';

/// وسيطة الانتقال من `camera_screen.dart` إلى هذه الشاشة عبر `extra`
/// في `go_router` — تحمل نفس نسخة [PhotosCubit] المُحمَّلة أصلاً (كي
/// تبقى `PhotosData.project`/`currentUser` متاحة دون إعادة تحميل) +
/// الصورة الخام الملتقطة للتو (`CapturedImage`، لم تُضغَط أو تُدرَج في
/// أي طابور بعد).
class PhotoAttachRouteArgs {
  const PhotoAttachRouteArgs({required this.cubit, required this.captured});

  final PhotosCubit cubit;
  final CapturedImage captured;
}

/// شاشة ربط الصورة الملتقطة بكيان + اختيار الوسوم
/// (`RoutePaths.photosAttach`، `/photos/attach`) — الخطوة الثانية
/// والأخيرة من تدفّق الإضافة، تليها مباشرة
/// `PhotosCubit.enqueueCapturedImage` (ضغط + إدراج في طابور الرفع
/// المحلي) ثم العودة لـ `my_photos_screen.dart`.
///
/// ⚠️ اختيار الكيان المحدَّد هنا مبسَّط عمداً في هذه الخطوة (Prompt
/// 18): لا يوجد بعد أي منتقي متصفِّح لعناصر ميزات أخرى (تقرير ميداني
/// محدد، مهمة محددة، عنصر قائمة ملاحظات محدد) — تلك الميزات (`punch_list`
/// Prompt 19 وما بعدها) لم تُبنَ واجهاتها الكاملة بعد. الافتراضي
/// العملي الوحيد المتاح فعلياً الآن هو ربط الصورة بـ"المشروع" نفسه
/// مباشرة (`RelatedEntityType.project`)، مع إمكانية اختيار نوع كيان
/// آخر يدوياً وإدخال معرّفه إن كان معروفاً للمستخدم مسبقاً (مثال: تعليق
/// صورة على تقرير أرسله للتو من `features/field_reports/`، فيعرف
/// معرّفه). تحسين هذا لاحقاً بمنتقي بصري حقيقي متروك عمداً لخطوة لاحقة
/// عندما تُبنى تلك الميزات فعلياً — لا معنى لبناء منتقٍ لبيانات لا
/// واجهة تصفّح لها بعد.
class PhotoAttachScreen extends StatefulWidget {
  const PhotoAttachScreen({required this.args, super.key});

  final PhotoAttachRouteArgs args;

  @override
  State<PhotoAttachScreen> createState() => _PhotoAttachScreenState();
}

class _PhotoAttachScreenState extends State<PhotoAttachScreen> {
  RelatedEntityType _entityType = RelatedEntityType.project;
  final TextEditingController _customEntityIdController = TextEditingController();
  List<String> _tags = <String>[];
  String _captionText = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _customEntityIdController.dispose();
    super.dispose();
  }

  String? get _projectId {
    final PhotosState state = widget.args.cubit.state;
    return state.maybeWhen(
      loaded: (PhotosData data) => data.project.id,
      orElse: () => null,
    );
  }

  Future<void> _save(BuildContext context) async {
    final String? projectId = _projectId;
    final String entityId = _entityType == RelatedEntityType.project
        ? (projectId ?? '')
        : _customEntityIdController.text.trim();

    if (entityId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال معرّف الكيان المرتبط.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final bool success = await widget.args.cubit.enqueueCapturedImage(
      captured: widget.args.captured,
      relatedEntityType: _entityType,
      relatedEntityId: entityId,
      tags: _tags,
      captionText: _captionText,
    );

    if (!context.mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ الصورة محلياً. حاول مجدداً.')),
      );
      return;
    }

    context.go(RoutePaths.photos);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhotosCubit>.value(
      value: widget.args.cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('ربط الصورة')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(widget.args.captured.bytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: AvahiSpacing.lg),
              Text('مرتبطة بـ', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AvahiSpacing.xs),
              AvahiDropdown<RelatedEntityType>(
                value: _entityType,
                items: RelatedEntityType.values
                    .map(
                      (RelatedEntityType type) => AvahiDropdownItem<RelatedEntityType>(
                        value: type,
                        label: type.displayNameAr,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (RelatedEntityType? type) {
                  if (type != null) setState(() => _entityType = type);
                },
              ),
              if (_entityType != RelatedEntityType.project) ...<Widget>[
                const SizedBox(height: AvahiSpacing.sm),
                TextField(
                  controller: _customEntityIdController,
                  decoration: const InputDecoration(
                    labelText: 'معرّف الكيان',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: AvahiSpacing.lg),
              PhotoTagSelector(
                selectedTags: _tags,
                onTagsChanged: (List<String> tags) => setState(() => _tags = tags),
                captionText: _captionText,
                onCaptionChanged: (String text) => _captionText = text,
              ),
              const SizedBox(height: AvahiSpacing.xl),
              AvahiButton(
                label: 'حفظ الصورة',
                icon: Icons.check,
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : () => _save(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
