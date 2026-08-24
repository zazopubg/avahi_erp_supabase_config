import 'package:flutter/material.dart';

import '../../theme/avahi_colors.dart';

/// أحجام الصورة الرمزية المتاحة.
enum AvatarSize { small, medium, large, xlarge }

/// صورة رمزية موحّدة (Avatar) لتطبيق Avahi — تعرض صورة شبكية عبر رابط
/// [imageUrl] عند توفره، أو الأحرف الأولى من [name] كبديل، مع شارة حالة
/// صغيرة اختيارية (مثال: متصل/غير متصل).
///
/// مكوّن عرض بحت — لا يحمّل أي بيانات مستخدم فعلية.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.medium,
    this.showStatusDot = false,
    this.isOnline = false,
  });

  /// رابط صورة الملف الشخصي (اختياري).
  final String? imageUrl;

  /// اسم المستخدم؛ تُستخرج منه الأحرف الأولى إذا لم تتوفر [imageUrl].
  final String? name;

  final AvatarSize size;

  /// عند `true`، تُعرض نقطة حالة صغيرة في الزاوية (متصل/غير متصل).
  final bool showStatusDot;

  final bool isOnline;

  double get _dimension => switch (size) {
        AvatarSize.small => 28,
        AvatarSize.medium => 40,
        AvatarSize.large => 56,
        AvatarSize.xlarge => 96,
      };

  double get _fontSize => switch (size) {
        AvatarSize.small => 12,
        AvatarSize.medium => 16,
        AvatarSize.large => 22,
        AvatarSize.xlarge => 36,
      };

  String get _initials {
    final String trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '؟';

    final List<String> parts =
        trimmed.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final String first = parts.first.substring(0, 1);
    final String last = parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    final Widget circle = ClipOval(
      child: SizedBox(
        width: _dimension,
        height: _dimension,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsFallback(
                  initials: _initials,
                  fontSize: _fontSize,
                  colors: colors,
                ),
              )
            : _InitialsFallback(
                initials: _initials,
                fontSize: _fontSize,
                colors: colors,
              ),
      ),
    );

    if (!showStatusDot) return circle;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        circle,
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: Container(
            width: _dimension * 0.28,
            height: _dimension * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? colors.success : colors.onSurfaceVariant,
              border: Border.all(color: colors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({
    required this.initials,
    required this.fontSize,
    required this.colors,
  });

  final String initials;
  final double fontSize;
  final AvahiColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.brandContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: colors.onBrandContainer,
        ),
      ),
    );
  }
}
