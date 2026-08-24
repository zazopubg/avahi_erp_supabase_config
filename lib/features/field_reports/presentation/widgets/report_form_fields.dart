import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';

/// حقول محتوى التقرير النصية الخمسة (العمل المُنجز، المواد المستخدَمة،
/// المعدات المستخدَمة، المشاكل/الملاحظات، ملاحظات إضافية) — مجمّعة في
/// ودجة واحدة لتفادي تكرار خمسة `TextEditingController`s منفصلة داخل
/// `report_form_screen.dart` نفسها.
///
/// كل حقل يحمل `TextEditingController` خاصاً به داخلياً، مُهيَّأ بالقيمة
/// الأولية فقط (لا يُعاد تحديثه لاحقاً من [ReportFormData] الخارجية —
/// نفس الحقل هو مصدر الحقيقة أثناء الكتابة، بخلاف `weather_selector.dart`
/// الذي يستقبل تحديثات خارجية فعلية من التعبئة التلقائية).
class ReportFormFields extends StatefulWidget {
  const ReportFormFields({
    required this.workPerformed,
    required this.materialsUsed,
    required this.equipmentUsed,
    required this.issues,
    required this.notes,
    required this.onWorkPerformedChanged,
    required this.onMaterialsUsedChanged,
    required this.onEquipmentUsedChanged,
    required this.onIssuesChanged,
    required this.onNotesChanged,
    super.key,
    this.workPerformedError,
  });

  final String? workPerformed;
  final String? materialsUsed;
  final String? equipmentUsed;
  final String? issues;
  final String? notes;

  final ValueChanged<String> onWorkPerformedChanged;
  final ValueChanged<String> onMaterialsUsedChanged;
  final ValueChanged<String> onEquipmentUsedChanged;
  final ValueChanged<String> onIssuesChanged;
  final ValueChanged<String> onNotesChanged;

  /// رسالة تحقق حقل "العمل المُنجز" — الحقل الجوهري الوحيد الإلزامي
  /// قبل التقديم (`ReportValidator.validateForSubmission`).
  final String? workPerformedError;

  @override
  State<ReportFormFields> createState() => _ReportFormFieldsState();
}

class _ReportFormFieldsState extends State<ReportFormFields> {
  late final TextEditingController _workController;
  late final TextEditingController _materialsController;
  late final TextEditingController _equipmentController;
  late final TextEditingController _issuesController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _workController = TextEditingController(text: widget.workPerformed ?? '');
    _materialsController = TextEditingController(text: widget.materialsUsed ?? '');
    _equipmentController = TextEditingController(text: widget.equipmentUsed ?? '');
    _issuesController = TextEditingController(text: widget.issues ?? '');
    _notesController = TextEditingController(text: widget.notes ?? '');
  }

  @override
  void dispose() {
    _workController.dispose();
    _materialsController.dispose();
    _equipmentController.dispose();
    _issuesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AvahiTextField(
          controller: _workController,
          label: 'العمل المُنجز *',
          hint: 'وصف موجز لأعمال اليوم المُنجزة في الموقع',
          maxLines: 4,
          minLines: 3,
          errorText: widget.workPerformedError,
          onChanged: widget.onWorkPerformedChanged,
        ),
        const SizedBox(height: AvahiSpacing.md),
        AvahiTextField(
          controller: _materialsController,
          label: 'المواد المستخدَمة',
          hint: 'اختياري — مثال: 20 كيس إسمنت، 5 م³ رمل...',
          maxLines: 3,
          minLines: 2,
          onChanged: widget.onMaterialsUsedChanged,
        ),
        const SizedBox(height: AvahiSpacing.md),
        AvahiTextField(
          controller: _equipmentController,
          label: 'المعدات المستخدَمة',
          hint: 'اختياري — مثال: حفّار، رافعة برجية...',
          maxLines: 3,
          minLines: 2,
          onChanged: widget.onEquipmentUsedChanged,
        ),
        const SizedBox(height: AvahiSpacing.md),
        AvahiTextField(
          controller: _issuesController,
          label: 'مشاكل/عوائق',
          hint: 'اختياري — أي مشكلة واجهت سير العمل اليوم',
          maxLines: 3,
          minLines: 2,
          onChanged: widget.onIssuesChanged,
        ),
        const SizedBox(height: AvahiSpacing.md),
        AvahiTextField(
          controller: _notesController,
          label: 'ملاحظات إضافية',
          hint: 'اختياري',
          maxLines: 3,
          minLines: 2,
          onChanged: widget.onNotesChanged,
        ),
      ],
    );
  }
}
