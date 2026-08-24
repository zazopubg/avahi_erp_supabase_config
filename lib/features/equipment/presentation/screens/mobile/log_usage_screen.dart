import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/equipment.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../state/equipment_cubit.dart';
import '../../state/equipment_state.dart';
import '../../widgets/equipment_status_badge.dart';
import '../../widgets/usage_hours_chart.dart';

/// حزمة وسيطة (Args) تُمرَّر عبر `extra:` لمسار
/// `RouteNames.equipmentLogUsage` (`/equipment/log-usage`) — تحمل
/// [Equipment] المُختارة **و**نسخة [EquipmentCubit] الحيّة نفسها التي
/// فتحت الشاشة (من `my_equipment_screen.dart` أو
/// `equipment_details.dart`)، بنفس نمط `PunchItemDetailsRouteArgs`/
/// `DocumentRouteArgs` تماماً — يضمن أن تسجيل الساعات هنا ينعكس فوراً
/// على نفس القائمة خلفها عند العودة إليها.
class LogUsageRouteArgs {
  const LogUsageRouteArgs({required this.equipment, required this.cubit});

  final Equipment equipment;
  final EquipmentCubit cubit;
}

/// شاشة كاملة (بلا حواف تنقّل ثابتة، خارج `ShellRoute` — بنفس منطق
/// `PunchItemCreateScreen`/`CameraScreen`) مخصّصة لتسجيل قراءة ساعات
/// تشغيل يومية لمعدة واحدة، مع ملاحظة اختيارية وعرض رسم بياني تراكمي
/// لما سُجِّل خلال هذه الجلسة (`usage_hours_chart.dart`).
///
/// ⚠️ [note] هنا لا يُحفَظ على الخادم إطلاقاً (لا عمود مخصّص له في
/// `public.equipment`، انظر توثيق القرار الكامل في
/// `EquipmentCubit.logUsageHours`) — يظهر فقط ضمن الرسم البياني
/// والسجل المحلي لهذه الجلسة.
class LogUsageScreen extends StatefulWidget {
  const LogUsageScreen({required this.args, super.key});

  final LogUsageRouteArgs args;

  @override
  State<LogUsageScreen> createState() => _LogUsageScreenState();
}

class _LogUsageScreenState extends State<LogUsageScreen> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _hoursError;

  /// آخر نسخة معروفة من [Equipment] المستهدفة — تُحدَّث محلياً عند
  /// نجاح كل تسجيل (`EquipmentCubit.logUsageHours` يُعيد النسخة
  /// المحدَّثة ضمن [LogUsageOutcome.equipment]) بدل الاعتماد فقط على
  /// [LogUsageRouteArgs.equipment] الثابتة الأصلية — كي تعكس بطاقة
  /// "ساعات التشغيل التراكمية الحالية" أعلى الشاشة كل تسجيل لاحق دون
  /// مغادرتها.
  late Equipment _equipment;

  @override
  void initState() {
    super.initState();
    _equipment = widget.args.equipment;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final double? hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) {
      setState(() => _hoursError = 'أدخل عدد ساعات صحيحاً أكبر من صفر.');
      return;
    }
    setState(() {
      _hoursError = null;
      _isSubmitting = true;
    });

    final LogUsageOutcome outcome = await widget.args.cubit.logUsageHours(
      equipment: _equipment,
      additionalHours: hours,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!outcome.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر تسجيل ساعات التشغيل، حاول مجدداً.'),
        ),
      );
      return;
    }

    setState(() {
      _equipment = outcome.equipment ?? _equipment;
      _hoursController.clear();
      _noteController.clear();
    });

    if (outcome.maintenanceThresholdExceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تنبيه: تجاوزت هذه المعدة عتبة الصيانة الموصى بها — يُنصح بجدولة صيانة قريباً.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل ساعات تشغيل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _equipment.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                EquipmentStatusBadge(status: _equipment.status),
              ],
            ),
            const SizedBox(height: AvahiSpacing.xxs),
            Text(
              'ساعات التشغيل التراكمية الحالية: '
              '${_equipment.usageHours.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AvahiSpacing.lg),
            AvahiTextField(
              controller: _hoursController,
              label: 'عدد الساعات المُضافة اليوم',
              hint: 'مثال: 8',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: _hoursError,
            ),
            const SizedBox(height: AvahiSpacing.sm),
            AvahiTextField(
              controller: _noteController,
              label: 'ملاحظة (اختياري)',
              maxLines: 3,
            ),
            const SizedBox(height: AvahiSpacing.lg),
            AvahiButton(
              label: 'تسجيل',
              isFullWidth: true,
              isLoading: _isSubmitting,
              icon: Icons.check,
              onPressed: _submit,
            ),
            const SizedBox(height: AvahiSpacing.xl),
            Text(
              'سجل الجلسة الحالية',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AvahiSpacing.sm),
            BlocBuilder<EquipmentCubit, EquipmentState>(
              bloc: widget.args.cubit,
              builder: (BuildContext context, EquipmentState state) {
                final List<UsageLogEntry> entries =
                    state.dataOrNull?.usageLogByEquipmentId[_equipment.id] ??
                        const <UsageLogEntry>[];
                return UsageHoursChart(entries: entries);
              },
            ),
          ],
        ),
      ),
    );
  }
}
