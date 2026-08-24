import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/leave_request.dart';
import '../../../../../domain/enums/leave_type.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../state/leave_cubit.dart';
import '../../state/leave_state.dart';
import '../../widgets/date_range_picker_field.dart';
import '../../widgets/leave_type_selector_items.dart';

/// نموذج تقديم طلب إجازة جديد موحّد — `create_leave_request_screen.dart`
/// (Prompt 24)، مفتوحة عبر `Navigator.push` من
/// `my_leave_requests_screen.dart` مشاركةً لنفس نسخة [LeaveCubit]
/// (انظر توثيق القرار الكامل هناك)، بنفس أسلوب فتح
/// `report_form_screen.dart` لشاشة التوقيع الفرعية ضمن نفس الميزة.
///
/// التحقق من صحة المدى الزمني وعدم تداخله مع طلبات قائمة يتم بالكامل
/// ضمن `LeaveValidator`/`RequestLeaveUsecase` (طبقة `domain/`) عند
/// الإرسال الفعلي — هذه الشاشة تتحقق محلياً فقط من اكتمال الحقول
/// الأساسية (نوع الإجازة، تاريخا البداية/النهاية) قبل تفعيل زر
/// "إرسال"، ثم تعرض [LeaveData.submitErrorMessage] (تحقّق منطقي محدَّد
/// من الخادم/`domain/`، مثل تداخل التواريخ) عبر `SnackBar` عند الفشل.
class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen> {
  LeaveType _leaveType = LeaveType.annual;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  bool get _dateRangeInvalid =>
      _startDate != null && _endDate != null && _endDate!.isBefore(_startDate!);

  bool get _canSubmit =>
      _startDate != null && _endDate != null && !_dateRangeInvalid;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_canSubmit) return;

    final LeaveRequest? created =
        await context.read<LeaveCubit>().submitLeaveRequest(
              leaveType: _leaveType,
              startDate: _startDate!,
              endDate: _endDate!,
              reason: _reasonController.text,
            );

    if (!context.mounted) return;

    if (created != null) {
      context.showSnackBar('تم تقديم طلب الإجازة بنجاح.');
      Navigator.of(context).pop();
      return;
    }

    final String message = context.read<LeaveCubit>().state.dataOrNull?.submitErrorMessage ??
        'تعذّر تقديم طلب الإجازة، حاول مجدداً.';
    context.showSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (BuildContext context, LeaveState state) {
        final LeaveData? data = state.dataOrNull;
        final bool isSubmitting = data?.isSubmitting ?? false;

        return Scaffold(
          appBar: AppBar(title: const Text('طلب إجازة جديد')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('نوع الإجازة', style: context.textTheme.labelLarge),
                const SizedBox(height: AvahiSpacing.xs),
                AvahiDropdown<LeaveType>(
                  value: _leaveType,
                  items: kLeaveTypeDropdownItems,
                  onChanged: (LeaveType? value) {
                    if (value != null) setState(() => _leaveType = value);
                  },
                ),
                const SizedBox(height: AvahiSpacing.lg),
                Text('المدى الزمني', style: context.textTheme.labelLarge),
                const SizedBox(height: AvahiSpacing.xs),
                DateRangePickerField(
                  startDate: _startDate,
                  endDate: _endDate,
                  enabled: !isSubmitting,
                  errorText: _dateRangeInvalid
                      ? 'يجب ألا يسبق تاريخ النهاية تاريخ البداية.'
                      : null,
                  onStartDateChanged: (DateTime date) => setState(() {
                    _startDate = date;
                    if (_endDate != null && _endDate!.isBefore(date)) {
                      _endDate = null;
                    }
                  }),
                  onEndDateChanged: (DateTime date) =>
                      setState(() => _endDate = date),
                ),
                const SizedBox(height: AvahiSpacing.lg),
                Text('السبب (اختياري)', style: context.textTheme.labelLarge),
                const SizedBox(height: AvahiSpacing.xs),
                AvahiTextField(
                  controller: _reasonController,
                  hint: 'أضف تفاصيل إضافية إن رغبت...',
                  maxLines: 3,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: AvahiSpacing.xl),
                AvahiButton(
                  label: 'إرسال الطلب',
                  isFullWidth: true,
                  isLoading: isSubmitting,
                  onPressed: _canSubmit ? () => _submit(context) : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
