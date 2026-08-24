import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';

/// زرَّا اعتماد/رفض طلب إجازة — `leave_request_review.dart`. الرفض
/// يفتح حواراً وسيطاً لطلب سبب الرفض (إلزامي) قبل تأكيد الاستدعاء
/// الفعلي؛ الاعتماد فوري بلا حوار وسيط. نسخة طبق الأصل من
/// `ReportApprovalActions` (`features/field_reports/`, Prompt 17). 🆕
class LeaveApprovalActions extends StatelessWidget {
  const LeaveApprovalActions({
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final bool isProcessing;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;

  Future<void> _promptRejectionReason(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('سبب الرفض'),
          content: Form(
            key: formKey,
            child: AvahiTextField(
              controller: controller,
              label: 'اذكر سبب رفض طلب الإجازة',
              maxLines: 3,
              minLines: 2,
              autofocus: true,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty) ? 'سبب الرفض مطلوب.' : null,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AvahiSpacing.md,
            0,
            AvahiSpacing.md,
            AvahiSpacing.md,
          ),
          actions: <Widget>[
            AvahiButton(
              label: 'إلغاء',
              variant: AvahiButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AvahiButton(
              label: 'تأكيد الرفض',
              variant: AvahiButtonVariant.danger,
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) onReject(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AvahiButton(
            label: 'رفض',
            variant: AvahiButtonVariant.danger,
            icon: Icons.close,
            isLoading: isProcessing,
            onPressed: isProcessing ? null : () => _promptRejectionReason(context),
          ),
        ),
        const SizedBox(width: AvahiSpacing.sm),
        Expanded(
          child: AvahiButton(
            label: 'اعتماد',
            icon: Icons.check,
            isLoading: isProcessing,
            onPressed: isProcessing ? null : onApprove,
          ),
        ),
      ],
    );
  }
}
