import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/permissions.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/utils/number_formatter.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/document.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../state/documents_cubit.dart';
import '../../state/documents_state.dart';
import '../../widgets/document_card.dart';
import '../shared/document_route_args.dart';

/// لوحة معاينة/إدارة مستند واحد — تعرض معاينة الملف مباشرة (`printing`
/// لملفات PDF، أو زر "فتح في نافذة جديدة" لبقية الأنواع)، البيانات
/// الوصفية الكاملة، وإجراءات الرفع/الأرشفة المتاحة حسب صلاحيات
/// المستخدم الحالي.
///
/// ⚠️ قرار تصميم مهم: هذا الصنف [DocumentViewerPanel] يقرأ حصراً
/// [DocumentsData.selectedDocument] (عبر `DocumentsCubit.selectDocument`)
/// بدل استقبال `documentId` وحلّه يدوياً في كل مرة (بخلاف
/// `PunchItemManage._resolve`) — لأن `documents_manager.dart` (اللوحة
/// المضمّنة) و[DocumentViewerScreen] (الصفحة الموجَّهة الكاملة أدناه)
/// كلاهما يحتاج نفس "المستند المختار حالياً" تماماً، فتوحيد المصدر عبر
/// حالة `DocumentsCubit` نفسها (بدل تكرار منطق حلّ معرّف في كل موضع)
/// يبقيهما متزامنين تلقائياً دون أي كود إضافي.
class DocumentViewerPanel extends StatelessWidget {
  const DocumentViewerPanel({super.key, this.onClose, this.embedded = true});

  /// عند تمريرها، يُعرض زر إغلاق أعلى اللوحة (`documents_manager.dart`
  /// المضمّنة). [DocumentViewerScreen] الصفحة الكاملة تستخدم `AppBar`
  /// خاصاً بها بدلاً منها.
  final VoidCallback? onClose;

  /// `true` ضمن `documents_manager.dart` (حدود جانبية + عرض مضغوط)،
  /// `false` ضمن [DocumentViewerScreen] (صفحة كاملة بلا حدود جانبية).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (BuildContext context, DocumentsState state) {
        final Document? document = state.dataOrNull?.selectedDocument;

        final Widget content = document == null
            ? Center(
                child: Text(
                  'اختر مستنداً لعرض تفاصيله ومعاينته',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            : _ViewerContent(document: document, onClose: onClose);

        if (!embedded) return content;

        return Container(
          width: 420,
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(left: BorderSide(color: colors.outlineVariant)),
          ),
          child: content,
        );
      },
    );
  }
}

/// صفحة كاملة موجَّهة لمسار `/documents/:id` — تُغلِّف [DocumentViewerPanel]
/// نفسها ضمن `Scaffold`+`AppBar` مستقلَّين، وتُقدِّم [DocumentsCubit]
/// المُمرَّرة عبر [args] (نفس نسخة `documents_manager.dart`/
/// `documents_list.dart` التي فتحت هذه الصفحة، بنفس نمط
/// `PunchItemDetailsScreen`) — بلا إنشاء نسخة `Cubit` جديدة، ثم تختار
/// [DocumentRouteArgs.document] فوراً عبر `DocumentsCubit.selectDocument`
/// كي تعرضه [DocumentViewerPanel] مباشرة.
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({required this.args, super.key});

  final DocumentRouteArgs args;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  @override
  void initState() {
    super.initState();
    widget.args.cubit.selectDocument(widget.args.document);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentsCubit>.value(
      value: widget.args.cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.args.document.title)),
        body: const DocumentViewerPanel(embedded: false),
      ),
    );
  }
}

class _ViewerContent extends StatefulWidget {
  const _ViewerContent({required this.document, this.onClose});

  final Document document;
  final VoidCallback? onClose;

  @override
  State<_ViewerContent> createState() => _ViewerContentState();
}

class _ViewerContentState extends State<_ViewerContent> {
  bool _isBusy = false;

  Future<void> _uploadNewVersion(BuildContext context) async {
    final DocumentsCubit cubit = context.read<DocumentsCubit>();
    final pickedFile = await cubit.pickDocumentFile();
    if (pickedFile == null || !context.mounted) return;

    setState(() => _isBusy = true);
    final Document? updated = await cubit.uploadNewVersion(
      previousVersion: widget.document,
      file: pickedFile,
    );
    if (!context.mounted) return;
    setState(() => _isBusy = false);

    if (updated != null) {
      cubit.selectDocument(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر رفع الإصدار الجديد.')),
      );
    }
  }

  Future<void> _archive(BuildContext context) async {
    final DocumentsCubit cubit = context.read<DocumentsCubit>();
    await AvahiDialog.show(
      context,
      title: 'أرشفة المستند',
      message: 'سيُنقل "${widget.document.title}" إلى الأرشيف ولن يظهر '
          'ضمن القائمة الافتراضية. يمكن استعادته لاحقاً عبر تفعيل '
          '"إظهار المؤرشف".',
      confirmLabel: 'أرشفة',
      cancelLabel: 'إلغاء',
      isDestructive: true,
      onConfirm: () async {
        Navigator.of(context).pop();
        final bool success = await cubit.archiveDocument(widget.document);
        if (!context.mounted) return;
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّرت أرشفة المستند.')),
          );
        }
      },
    );
  }

  Future<void> _openInNewTab(BuildContext context) async {
    final DocumentsCubit cubit = context.read<DocumentsCubit>();
    final String? url = await cubit.getPreviewUrl(widget.document);
    if (url == null || !context.mounted) return;
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final AppUser? user = context.read<AuthCubit>().state.maybeWhen<AppUser?>(
          orElse: () => null,
          authenticated: (AppUser u, _) => u,
        );
    final bool canUpload = user != null &&
        RolePermissions.has(user.role, Permission.documentsUpload);
    final bool canArchive = user != null &&
        RolePermissions.has(user.role, Permission.documentsDeleteAny);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.document.title,
                  style: context.textTheme.titleMedium,
                ),
              ),
              if (widget.onClose != null)
                IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AvahiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PreviewArea(document: widget.document),
                const SizedBox(height: AvahiSpacing.md),
                _MetaRow(label: 'التصنيف', value: widget.document.category ?? '—'),
                _MetaRow(
                  label: 'الحجم',
                  value: widget.document.fileSizeBytes == null
                      ? '—'
                      : NumberFormatter.fileSize(widget.document.fileSizeBytes!),
                ),
                _MetaRow(label: 'الإصدار', value: '${widget.document.version}'),
                _MetaRow(
                  label: 'تاريخ الرفع',
                  value: DateFormatter.shortDate(widget.document.createdAt),
                ),
                if (widget.document.description != null &&
                    widget.document.description!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AvahiSpacing.sm),
                  Text(
                    widget.document.description!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AvahiSpacing.md),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AvahiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AvahiButton(
                label: 'فتح في نافذة جديدة',
                icon: Icons.open_in_new,
                variant: AvahiButtonVariant.secondary,
                onPressed: () => _openInNewTab(context),
              ),
              if (canUpload && !widget.document.isArchived) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xs),
                AvahiButton(
                  label: 'رفع إصدار جديد',
                  icon: Icons.upload_file_outlined,
                  variant: AvahiButtonVariant.secondary,
                  isLoading: _isBusy,
                  onPressed: () => _uploadNewVersion(context),
                ),
              ],
              if (canArchive && !widget.document.isArchived) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xs),
                AvahiButton(
                  label: 'أرشفة المستند',
                  icon: Icons.archive_outlined,
                  variant: AvahiButtonVariant.danger,
                  onPressed: () => _archive(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// منطقة المعاينة الفعلية — `PdfPreview` (حزمة `printing`) لملفات PDF
/// (تجلب البايتات من الرابط الموقّت المُوقَّع عبر `DocumentsCubit.getPreviewUrl`
/// ثم تعرضها، مع أزرار طباعة/مشاركة مدمجة تلقائياً من الحزمة نفسها)،
/// أو بطاقة أيقونة بسيطة + توجيه لزر "فتح في نافذة جديدة" أسفل اللوحة
/// لبقية الأنواع (Word/Excel...) التي لا تدعمها `printing` مباشرة.
class _PreviewArea extends StatelessWidget {
  const _PreviewArea({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool isPdf = (document.fileType ?? '').toLowerCase() == 'pdf';

    if (!isPdf) {
      final (IconData icon, Color iconColor) = documentFileVisuals(
        colors,
        document.fileType,
      );
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: AvahiSpacing.xs),
            Text(
              'لا تتوفر معاينة مباشرة لهذا النوع — استخدم "فتح في نافذة جديدة".',
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 480,
      child: PdfPreview(
        build: (format) async {
          final DocumentsCubit cubit = context.read<DocumentsCubit>();
          final String? url = await cubit.getPreviewUrl(document);
          if (url == null) return Uint8List(0);
          final http.Response response = await http.get(Uri.parse(url));
          return response.bodyBytes;
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(value, style: context.textTheme.labelMedium),
        ],
      ),
    );
  }
}
