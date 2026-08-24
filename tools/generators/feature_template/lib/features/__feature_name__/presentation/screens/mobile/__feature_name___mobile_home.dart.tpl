import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/__feature_name___cubit.dart';
import '../../state/__feature_name___state.dart';

/// نقطة الدخول الموحّدة لميزة `__feature_name__` على الهاتف — بنفس
/// نمط `my_equipment_screen.dart`/`documents_home.dart`.
///
/// TODO: أعد تسمية هذا الصنف وملفه ليعكس اسم الشاشة الفعلي
/// (مثال: `my___feature_name___screen.dart`)، وابنِ المحتوى الفعلي
/// داخل `loaded` بدل عنصر `ListView` النموذجي أدناه.
class __FeatureName__MobileHome extends StatelessWidget {
  const __FeatureName__MobileHome({super.key});

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
                return const EmptyState(
                  title: 'لا توجد عناصر بعد', // TODO: ترجمة/تخصيص
                );
              }
              return ListView.builder(
                itemCount: data.items.length,
                itemBuilder: (BuildContext context, int index) {
                  // TODO: استبدل هذا بودجة عرض العنصر الفعلية.
                  return ListTile(title: Text(data.items[index].toString()));
                },
              );
            },
            error: (Object failure) => ErrorView(
              title: 'تعذّر التحميل', // TODO: ترجمة/تخصيص
              onRetry: () {
                // TODO: context.read<__FeatureName__Cubit>().loadInitial(user);
              },
            ),
          );
        },
      ),
    );
  }
}
