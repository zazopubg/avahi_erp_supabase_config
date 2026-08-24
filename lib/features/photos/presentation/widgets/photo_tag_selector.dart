import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../state/photos_state.dart' show kAvailablePhotoTags;

/// منتقي وسوم تصنيفية (Chips) + حقل تعليق نصي حر — تستخدمه
/// `photo_attach_screen.dart` قبل استدعاء
/// `PhotosCubit.enqueueCapturedImage`. عرض بحت بالكامل: لا يبني نص
/// [SitePhoto.caption] النهائي بنفسه (تلك مسؤولية
/// `PhotosData.buildCaption` المُستدعاة من الشاشة الأم عند الحفظ)، بل
/// يُعيد فقط قائمة الوسوم المختارة الحالية + نص التعليق عبر
/// [onTagsChanged]/[onCaptionChanged].
class PhotoTagSelector extends StatefulWidget {
  const PhotoTagSelector({
    required this.selectedTags,
    required this.onTagsChanged,
    required this.captionText,
    required this.onCaptionChanged,
    super.key,
  });

  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final String captionText;
  final ValueChanged<String> onCaptionChanged;

  @override
  State<PhotoTagSelector> createState() => _PhotoTagSelectorState();
}

class _PhotoTagSelectorState extends State<PhotoTagSelector> {
  late final TextEditingController _captionController =
      TextEditingController(text: widget.captionText);

  void _toggleTag(String tag) {
    final List<String> updated = List<String>.from(widget.selectedTags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    widget.onTagsChanged(updated);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('الوسوم', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AvahiSpacing.xs),
        Wrap(
          spacing: AvahiSpacing.xs,
          runSpacing: AvahiSpacing.xs,
          children: kAvailablePhotoTags.map((String tag) {
            final bool selected = widget.selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: selected,
              onSelected: (_) => _toggleTag(tag),
              selectedColor: colors.brandContainer,
              checkmarkColor: colors.onBrandContainer,
              labelStyle: TextStyle(
                color: selected ? colors.onBrandContainer : colors.onSurfaceVariant,
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: AvahiSpacing.md),
        Text('تعليق (اختياري)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AvahiSpacing.xs),
        TextField(
          controller: _captionController,
          onChanged: widget.onCaptionChanged,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'وصف مختصر لهذه الصورة...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
