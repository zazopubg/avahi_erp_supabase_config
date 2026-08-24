import 'package:flutter/material.dart';

import '../../theme/avahi_spacing.dart';

/// أحجام مؤشر التحميل المتاحة.
enum LoadingIndicatorSize { small, medium, large }

/// مؤشر تحميل دائري موحّد لتطبيق Avahi، مع نص وصفي اختياري تحته.
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحميل بيانات فعلي.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = LoadingIndicatorSize.medium,
    this.label,
    this.color,
  });

  final LoadingIndicatorSize size;

  /// نص اختياري يُعرض أسفل المؤشر (مثال: "جارٍ التحميل...").
  final String? label;

  final Color? color;

  double get _dimension => switch (size) {
        LoadingIndicatorSize.small => 16,
        LoadingIndicatorSize.medium => 28,
        LoadingIndicatorSize.large => 40,
      };

  double get _strokeWidth => switch (size) {
        LoadingIndicatorSize.small => 2,
        LoadingIndicatorSize.medium => 3,
        LoadingIndicatorSize.large => 4,
      };

  @override
  Widget build(BuildContext context) {
    final Widget indicator = SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: _strokeWidth,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );

    if (label == null) return Center(child: indicator);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          indicator,
          const SizedBox(height: AvahiSpacing.sm),
          Text(label!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// نسخة مصمّمة لملء الشاشة بالكامل أثناء التحميل الأولي (Splash-like).
class FullScreenLoadingIndicator extends StatelessWidget {
  const FullScreenLoadingIndicator({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingIndicator(
        size: LoadingIndicatorSize.large,
        label: label,
      ),
    );
  }
}
