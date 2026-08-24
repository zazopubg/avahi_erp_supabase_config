import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/__feature_name___cubit.dart';
import '../../state/__feature_name___state.dart';

/// نسخة سطح المكتب من شاشة `__feature_name__` — تُستخدَم فقط إن كانت
/// الميزة تحتاج تفرّعاً فعلياً بين الهاتف وسطح المكتب (جدول كامل بدل
/// قائمة مثلاً). راجع
/// docs/architecture/05_responsive_web.md#أنماط-تفرّع-الشاشات-داخل-الميزات
/// أولاً — ميزات كثيرة تكتفي بشاشة واحدة بمنطق `ShellMode` داخلي، فلا
/// تُبنِ هذا الملف إلا إن كان التفرّع الكامل مبرَّراً فعلياً لميزتك.
///
/// TODO: أعد تسمية هذا الصنف وملفه (مثال: `__feature_name___registry.dart`)
/// وابنِ تخطيطاً جدولياً/أوسع مناسباً لسطح المكتب.
class __FeatureName__DesktopHome extends StatelessWidget {
  const __FeatureName__DesktopHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('__FeatureName__')), // TODO: ترجمة
      body: BlocBuilder<__FeatureName__Cubit, __FeatureName__State>(
        builder: (BuildContext context, __FeatureName__State state) {
          return state.when(
            loading: () => const LoadingIndicator(),
            loaded: (__FeatureName__Data data) {
              if (data.items.isEmpty) {
                return const EmptyState(title: 'لا توجد عناصر بعد');
              }
              // TODO: استبدل هذا بجدول/تخطيط سطح مكتب فعلي
              // (مثال: DataTable أو تخطيط قائمة + لوحة تفاصيل جانبية).
              return ListView.builder(
                itemCount: data.items.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(title: Text(data.items[index].toString()));
                },
              );
            },
            error: (Object failure) => const ErrorView(title: 'تعذّر التحميل'),
          );
        },
      ),
    );
  }
}
