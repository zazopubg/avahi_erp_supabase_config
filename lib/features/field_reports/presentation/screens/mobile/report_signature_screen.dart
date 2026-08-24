import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signature/signature.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../state/report_form_cubit.dart';
import '../../state/report_form_state.dart';
import '../../widgets/signature_capture_pad.dart';

/// شاشة التوقيع الرقمي الختامية — توقيع المشرف (إلزامي) وتوقيع العميل
/// (اختياري)، ثم زر واحد يستدعي [ReportFormCubit.signAndSubmit] الذي
/// يرفع التواقيع ويستدعي `sign_report_usecase` ثم `submit_report_usecase`
/// معاً (`draft` → `submitted`). عند نجاح التقديم، تُغلَق كل شاشات هذا
/// التقرير (`report_form_screen.dart`/`report_preview_screen.dart`/هذه
/// الشاشة معاً) عائدةً إلى `field_reports_mobile_home.dart` بضغطة زر
/// واحدة عبر `Navigator.popUntil`.
class ReportSignatureScreen extends StatefulWidget {
  const ReportSignatureScreen({super.key});

  @override
  State<ReportSignatureScreen> createState() => _ReportSignatureScreenState();
}

class _ReportSignatureScreenState extends State<ReportSignatureScreen> {
  late final SignatureController _supervisorController;
  late final SignatureController _clientController;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _supervisorController = SignatureController(exportBackgroundColor: Colors.transparent);
    _clientController = SignatureController(exportBackgroundColor: Colors.transparent);
  }

  @override
  void dispose() {
    _supervisorController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context, ReportFormCubit cubit) async {
    setState(() => _attemptedSubmit = true);

    if (_supervisorController.isEmpty) {
      context.showSnackBar('توقيع المشرف مطلوب قبل التقديم.');
      return;
    }

    final supervisorBytes = await _supervisorController.toPngBytes();
    if (supervisorBytes == null) {
      if (context.mounted) context.showSnackBar('تعذّر معالجة توقيع المشرف — حاول مجدداً.');
      return;
    }

    final clientBytes = _clientController.isNotEmpty
        ? await _clientController.toPngBytes()
        : null;

    final bool success = await cubit.signAndSubmit(
      supervisorSignatureBytes: supervisorBytes,
      clientSignatureBytes: clientBytes,
    );

    if (!context.mounted) return;

    if (success) {
      context.showSnackBar('تم تقديم التقرير بنجاح.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      context.showSnackBar('تعذّر تقديم التقرير — تحقق من الاتصال وحاول مجدداً.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportFormCubit, ReportFormState>(
      builder: (BuildContext context, ReportFormState state) {
        final ReportFormData? data = state.dataOrNull;
        if (data == null) return const Scaffold(body: LoadingIndicator());

        final ReportFormCubit cubit = context.read<ReportFormCubit>();

        return Scaffold(
          appBar: AppBar(title: const Text('التوقيع والتقديم')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'وقّع أدناه لتأكيد اعتماد بيانات هذا التقرير وتقديمه للمراجعة.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AvahiSpacing.lg),
                SignatureCapturePad(
                  controller: _supervisorController,
                  title: 'توقيع المشرف',
                  isRequired: true,
                  helperText: _attemptedSubmit && _supervisorController.isEmpty
                      ? 'توقيع المشرف مطلوب.'
                      : null,
                ),
                const SizedBox(height: AvahiSpacing.lg),
                SignatureCapturePad(
                  controller: _clientController,
                  title: 'توقيع العميل',
                  helperText: 'اختياري — إن حضر ممثل العميل الموقع.',
                ),
                const SizedBox(height: AvahiSpacing.xl),
                AvahiButton(
                  label: 'تقديم التقرير',
                  icon: Icons.send_outlined,
                  isFullWidth: true,
                  isLoading: data.isSigningAndSubmitting,
                  onPressed: data.isSigningAndSubmitting
                      ? null
                      : () => _handleSubmit(context, cubit),
                ),
                const SizedBox(height: AvahiSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
