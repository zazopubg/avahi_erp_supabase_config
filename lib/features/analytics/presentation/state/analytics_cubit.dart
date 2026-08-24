// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/attendance_record.dart';
import '../../../../domain/entities/equipment.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/enums/task_status.dart';
import '../../../../domain/usecases/attendance/get_project_attendance_usecase.dart';
import '../../../../domain/usecases/equipment/get_company_equipment_usecase.dart';
import '../../../../domain/usecases/projects/get_my_projects_usecase.dart';
import '../../../../domain/usecases/projects/get_project_dashboard_usecase.dart';
import '../../../../domain/usecases/tasks/get_project_tasks_usecase.dart';
import 'analytics_state.dart';

/// `Cubit` ميزة `features/analytics/` (Prompt 25) — يقود كل شاشات
/// الميزة (`analytics_dashboard.dart`/`project_analytics.dart`/
/// `attendance_analytics.dart`/`export_analytics_screen.dart`) عبر
/// [AnalyticsData] واحدة مجمّعة، بنفس فلسفة `ProjectsCubit`/
/// `EquipmentCubit`.
///
/// ⚠️ قرار تصميم مهم (لا مستودع/UseCase مخصّص جديد لهذه الميزة):
/// بخلاف كل ميزة سابقة (`equipment`/`leave_requests`...) هذه الميزة
/// **لا تضيف** أي عقد `domain/repositories/` أو `UseCase` جديد — هي
/// طبقة **تجميع (Aggregation)** بحتة فوق أربع نقاط قراءة موجودة أصلاً
/// ومسجَّلة في `core/di/domain_module.dart` منذ خطوات سابقة:
/// [GetMyProjectsUsecase] (Prompt 14)، [GetProjectDashboardUsecase]
/// (Prompt 14)، [GetProjectTasksUsecase] (Prompt 16)،
/// [GetProjectAttendanceUsecase] (Prompt 15)، و[GetCompanyEquipmentUsecase]
/// (Prompt 22) — بلا استثناء. هذا يطابق تماماً طبيعة "لوحة تحليلات
/// تنفيذية" فعلياً: تجميع بيانات موجودة من زوايا مختلفة، لا مصدر
/// بيانات مستقل بذاته.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required GetMyProjectsUsecase getMyProjectsUsecase,
    required GetProjectDashboardUsecase getProjectDashboardUsecase,
    required GetProjectTasksUsecase getProjectTasksUsecase,
    required GetProjectAttendanceUsecase getProjectAttendanceUsecase,
    required GetCompanyEquipmentUsecase getCompanyEquipmentUsecase,
  })  : _getMyProjectsUsecase = getMyProjectsUsecase,
        _getProjectDashboardUsecase = getProjectDashboardUsecase,
        _getProjectTasksUsecase = getProjectTasksUsecase,
        _getProjectAttendanceUsecase = getProjectAttendanceUsecase,
        _getCompanyEquipmentUsecase = getCompanyEquipmentUsecase,
        super(const AnalyticsInitial());

  final GetMyProjectsUsecase _getMyProjectsUsecase;
  final GetProjectDashboardUsecase _getProjectDashboardUsecase;
  final GetProjectTasksUsecase _getProjectTasksUsecase;
  final GetProjectAttendanceUsecase _getProjectAttendanceUsecase;
  final GetCompanyEquipmentUsecase _getCompanyEquipmentUsecase;

  /// طول المدى الزمني الافتراضي لسلسلة اتجاه الحضور عند [loadInitial]
  /// — يطابق حرفياً "30 يوماً" المطلوبة في وصف `attendance_trend_chart.dart`.
  static const int _defaultRangeDays = 30;

  // ── تحميل أولي ──────────────────────────────────────────────────

  /// يُستدعى مرة واحدة عند دخول `analytics_dashboard.dart`: يجلب كل
  /// مشاريع الشركة، ثم — لكل مشروع بالتوازي (`Future.wait`) — لوحة
  /// تحكّمه المجمّعة ومهامه الكاملة وسجلات حضوره ضمن المدى الافتراضي
  /// (آخر 30 يوماً)، وأخيراً معدات الشركة الكاملة مرة واحدة (بلا
  /// فلترة مشروع). فشل مصدر واحد جزئي (مثال: تعذّر جلب مهام مشروع
  /// واحد) لا يُسقط اللوحة كاملة — يُعامَل كقائمة فارغة لذلك المشروع
  /// فقط (`result.fold((_) => const [], ...)`، بنفس نمط
  /// `ProjectsCubit.loadDashboard`)؛ فقط فشل [GetMyProjectsUsecase]
  /// نفسها (المصدر الجذري الذي يبني عليه كل شيء آخر) يُنتج
  /// [AnalyticsError] كاملة.
  Future<void> loadInitial(AppUser user) async {
    emit(const AnalyticsLoading());

    final ResultOf<List<Project>> projectsResult =
        await _getMyProjectsUsecase(user.userId);

    await projectsResult.fold(
      (Failure failure) async => emit(AnalyticsError(failure)),
      (List<Project> projects) async {
        final DateTime now = DateTime.now();
        final DateTime rangeTo = DateTime(now.year, now.month, now.day);
        final DateTime rangeFrom =
            rangeTo.subtract(const Duration(days: _defaultRangeDays - 1));

        final _AggregatedProjectData aggregated = await _loadProjectAggregates(
          projects: projects,
          rangeFrom: rangeFrom,
          rangeTo: rangeTo,
        );

        final ResultOf<List<Equipment>> equipmentResult =
            await _getCompanyEquipmentUsecase();
        final List<Equipment> equipment = equipmentResult.fold(
          (Failure _) => const <Equipment>[],
          (List<Equipment> e) => e,
        );

        emit(
          AnalyticsLoaded(
            AnalyticsData(
              currentUser: user,
              companyProjects: projects,
              projectSummaries: aggregated.summaries,
              tasksByProjectId: aggregated.tasksByProjectId,
              attendanceByProjectId: aggregated.attendanceByProjectId,
              companyEquipment: equipment,
              rangeFrom: rangeFrom,
              rangeTo: rangeTo,
            ),
          ),
        );
      },
    );
  }

  /// يعيد تحميل اللوحة بالكامل محافظاً على [AnalyticsData.rangeFrom]/
  /// [AnalyticsData.rangeTo]/[AnalyticsData.selectedProjectId] الحاليين
  /// (سحب للتحديث من `analytics_dashboard.dart`).
  Future<void> refresh() async {
    final AnalyticsData? current = state.dataOrNull;
    if (current == null) return;

    final ResultOf<List<Project>> projectsResult =
        await _getMyProjectsUsecase(current.currentUser.userId);
    final List<Project>? projects =
        projectsResult.fold((Failure _) => null, (List<Project> p) => p);
    if (projects == null) return;

    final _AggregatedProjectData aggregated = await _loadProjectAggregates(
      projects: projects,
      rangeFrom: current.rangeFrom,
      rangeTo: current.rangeTo,
    );

    final ResultOf<List<Equipment>> equipmentResult =
        await _getCompanyEquipmentUsecase();
    final List<Equipment> equipment =
        equipmentResult.fold((Failure _) => const <Equipment>[], (e) => e);

    final AnalyticsData latest = state.dataOrNull ?? current;
    emit(
      AnalyticsLoaded(
        latest.copyWith(
          companyProjects: projects,
          projectSummaries: aggregated.summaries,
          tasksByProjectId: aggregated.tasksByProjectId,
          attendanceByProjectId: aggregated.attendanceByProjectId,
          companyEquipment: equipment,
        ),
      ),
    );
  }

  /// يجلب لوحة تحكّم/مهام/حضور كل مشروع بالتوازي ويبني
  /// [ProjectAnalyticsSummary] لكل واحد منها — منطق مشترك بين
  /// [loadInitial] و[refresh].
  Future<_AggregatedProjectData> _loadProjectAggregates({
    required List<Project> projects,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) async {
    final Map<String, ProjectAnalyticsSummary> summaries =
        <String, ProjectAnalyticsSummary>{};
    final Map<String, List<Task>> tasksByProjectId = <String, List<Task>>{};
    final Map<String, List<AttendanceRecord>> attendanceByProjectId =
        <String, List<AttendanceRecord>>{};

    await Future.wait<void>(
      projects.map((Project project) async {
        // ⚠️ الاستدعاءات الثلاثة أدناه تُطلَق متزامنة عمداً (Futures
        // تبدأ تنفيذها فوراً عند إنشائها في Dart، لا عند `await`ها) —
        // `Future.wait` الخارجية أعلاه توازي بين *المشاريع*، وهذا الفصل
        // الداخلي يوازي بين الاستعلامات الثلاثة *لنفس* المشروع، بدل
        // `Future.wait<dynamic>` بأنواع مختلطة تتطلب `as` غير آمن لاحقاً.
        final Future<ResultOf<Map<String, num>>> dashboardFuture =
            _getProjectDashboardUsecase(project.id);
        final Future<ResultOf<List<Task>>> tasksFuture =
            _getProjectTasksUsecase(project.id);
        final Future<ResultOf<List<AttendanceRecord>>> attendanceFuture =
            _getProjectAttendanceUsecase(
          projectId: project.id,
          from: rangeFrom,
          to: rangeTo.add(const Duration(days: 1)),
        );

        final ResultOf<Map<String, num>> dashboardResult =
            await dashboardFuture;
        final ResultOf<List<Task>> tasksResult = await tasksFuture;
        final ResultOf<List<AttendanceRecord>> attendanceResult =
            await attendanceFuture;

        final Map<String, num> dashboard = dashboardResult.fold(
          (Failure _) => const <String, num>{},
          (Map<String, num> d) => d,
        );
        final List<Task> tasks =
            tasksResult.fold((Failure _) => const <Task>[], (t) => t);
        final List<AttendanceRecord> attendance = attendanceResult.fold(
          (Failure _) => const <AttendanceRecord>[],
          (a) => a,
        );

        final int completedTasksCount =
            tasks.where((Task t) => t.status == TaskStatus.done).length;

        tasksByProjectId[project.id] = tasks;
        attendanceByProjectId[project.id] = attendance;
        summaries[project.id] = ProjectAnalyticsSummary(
          project: project,
          openTasksCount: (dashboard['openTasksCount'] ?? 0).toInt(),
          completedTasksCount: completedTasksCount,
          totalTasksCount: tasks.length,
          openPunchItemsCount: (dashboard['openPunchItemsCount'] ?? 0).toInt(),
          projectMembersCount: (dashboard['projectMembersCount'] ?? 0).toInt(),
          todayAttendanceCount:
              (dashboard['todayAttendanceCount'] ?? 0).toInt(),
          todayAttendanceRate:
              (dashboard['todayAttendanceRate'] ?? 0).toDouble(),
        );
      }),
    );

    return _AggregatedProjectData(
      summaries: summaries,
      tasksByProjectId: tasksByProjectId,
      attendanceByProjectId: attendanceByProjectId,
    );
  }

  // ── تصفية زمنية (`date_range_filter.dart`) ────────────────────────

  /// يعيد جلب [AnalyticsData.attendanceByProjectId] فقط ضمن المدى
  /// الجديد [from]–[to] — بقية بيانات اللوحة (المشاريع، المهام،
  /// المعدات) تبقى كما هي بلا إعادة تحميل، لأنها غير مرتبطة بمدى
  /// تاريخي أصلاً. يبقى [AnalyticsState] عند [AnalyticsLoaded] طوال
  /// هذه العملية (`isRefreshingRange` وحدها تتبدّل ضمن نفس [AnalyticsData]
  /// — انظر توثيق القرار الكامل في `AnalyticsData.isRefreshingRange`).
  Future<void> setDateRange({required DateTime from, required DateTime to}) async {
    final AnalyticsData? current = state.dataOrNull;
    if (current == null) return;

    emit(AnalyticsLoaded(current.copyWith(isRefreshingRange: true)));

    final Map<String, List<AttendanceRecord>> attendanceByProjectId =
        <String, List<AttendanceRecord>>{};

    await Future.wait<void>(
      current.companyProjects.map((Project project) async {
        final ResultOf<List<AttendanceRecord>> result =
            await _getProjectAttendanceUsecase(
          projectId: project.id,
          from: from,
          to: to.add(const Duration(days: 1)),
        );
        attendanceByProjectId[project.id] =
            result.fold((Failure _) => const <AttendanceRecord>[], (a) => a);
      }),
    );

    final AnalyticsData latest = state.dataOrNull ?? current;
    emit(
      AnalyticsLoaded(
        latest.copyWith(
          rangeFrom: from,
          rangeTo: to,
          attendanceByProjectId: attendanceByProjectId,
          isRefreshingRange: false,
        ),
      ),
    );
  }

  /// اختصارات مدى شائعة لـ `date_range_filter.dart` — 7/30/90 يوماً
  /// الأخيرة من اليوم الحالي.
  Future<void> setPresetRange(int days) async {
    final DateTime now = DateTime.now();
    final DateTime to = DateTime(now.year, now.month, now.day);
    final DateTime from = to.subtract(Duration(days: days - 1));
    await setDateRange(from: from, to: to);
  }

  // ── اختيار مشروع (`project_analytics.dart`) ───────────────────────

  /// يختار مشروعاً واحداً لعرض تحليلاته التفصيلية — تصفية عرض بحتة،
  /// كل البيانات محمَّلة مسبقاً ضمن [loadInitial] (بلا استدعاء شبكة
  /// إضافي)، بنفس منطق `ProjectsCubit.selectProject` عند وجود المشروع
  /// ضمن القائمة المحمَّلة مسبقاً.
  void selectProject(String? projectId) {
    final AnalyticsData? current = state.dataOrNull;
    if (current == null) return;
    emit(
      AnalyticsLoaded(
        current.copyWith(
          selectedProjectId: projectId,
          clearSelectedProjectId: projectId == null,
        ),
      ),
    );
  }

  // ── تصدير (`export_analytics_screen.dart`) ─────────────────────────

  /// يبني ملف PDF كاملاً للوحة التحليلات الحالية (KPIs + جدول تقدّم
  /// المشاريع + جدول توزيع المهام + جدول اتجاه الحضور) ثم يفتح واجهة
  /// طباعة/حفظ المتصفح الأصلية عبر `Printing.layoutPdf` (حزمة
  /// `printing`، مُستهلَكة أصلاً في `features/documents/` لمعاينة PDF
  /// — هنا أول استهلاك فعلي لها *لتوليد* PDF بدل معاينته فقط) — يتيح
  /// "حفظ كـ PDF" مباشرة من حوار الطباعة الأصلي للمتصفح، وهو ما يطابق
  /// فعلياً بيئة الويب الحصرية للتطبيق (انظر ملاحظات `pubspec.yaml`:
  /// "المشروع يستهدف الويب (Chrome) حصراً").
  Future<bool> exportDashboardAsPdf() async {
    final AnalyticsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(AnalyticsExporting(current, AnalyticsExportKind.pdf));
    try {
      final Uint8List bytes = await _buildDashboardPdfBytes(current);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name:
            'avahi-analytics-${DateFormatter.shortDate(DateTime.now())}.pdf',
      );
      emit(AnalyticsLoaded(current));
      return true;
    } catch (_) {
      emit(AnalyticsLoaded(current));
      return false;
    }
  }

  /// يستقبل بايتات صورة (PNG) مُلتقَطة مسبقاً من الشاشة عبر
  /// `RenderRepaintBoundary` (انظر `export_analytics_screen.dart` —
  /// الالتقاط نفسه يتطلّب وصولاً لشجرة الودجات فلا يمكن نقله إلى
  /// الـ Cubit، لكن كل ما بعده — إدارة حالة [AnalyticsExporting] وتنزيل
  /// الملف فعلياً في المتصفح — يبقى هنا) ويُنزّلها كملف عبر عنصر
  /// `<a download>` مؤقت (`dart:html`، متوافق حصراً مع بيئة الويب
  /// الوحيدة المستهدَفة — انظر نفس ملاحظة [exportDashboardAsPdf]).
  Future<bool> exportSectionAsImage({
    required Uint8List pngBytes,
    required String fileName,
  }) async {
    final AnalyticsData? current = state.dataOrNull;
    if (current == null) return false;

    emit(AnalyticsExporting(current, AnalyticsExportKind.image));
    try {
      _downloadBytesInBrowser(
        bytes: pngBytes,
        fileName: fileName,
        mimeType: 'image/png',
      );
      emit(AnalyticsLoaded(current));
      return true;
    } catch (_) {
      emit(AnalyticsLoaded(current));
      return false;
    }
  }

  void _downloadBytesInBrowser({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    final html.Blob blob = html.Blob(<Uint8List>[bytes], mimeType);
    final String url = html.Url.createObjectUrlFromBlob(blob);
    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<Uint8List> _buildDashboardPdfBytes(AnalyticsData data) async {
    final pw.Document doc = pw.Document();

    // ⚠️ قرار تصميم (خط Cairo المرفق محلياً، لا `PdfGoogleFonts`):
    // التطبيق يحمّل خط Cairo أصلاً كخط أساسي عبر `pubspec.yaml`
    // (`assets/fonts/Cairo-Regular.ttf`/`Cairo-Bold.ttf`، Prompt 00/01
    // — انظر `ui/theme/avahi_theme.dart`) وهو خط يدعم العربية بالكامل؛
    // استخدامه هنا عبر `rootBundle.load` بدل الاعتماد على تحميل خط
    // عبر الشبكة (`PdfGoogleFonts`) يتجنّب أي فشل صامت لتصدير PDF عند
    // ضعف الاتصال، ويضمن تطابق الخط المستخدَم في PDF مع خط واجهة
    // التطبيق نفسها.
    final ByteData regularFontData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ByteData boldFontData =
        await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final pw.Font baseFont = pw.Font.ttf(regularFontData);
    final pw.Font boldFont = pw.Font.ttf(boldFontData);
    final pw.TextStyle baseStyle = pw.TextStyle(font: baseFont, fontSize: 10);
    final pw.TextStyle titleStyle =
        pw.TextStyle(font: boldFont, fontSize: 18);
    final pw.TextStyle headingStyle =
        pw.TextStyle(font: boldFont, fontSize: 13);

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text('لوحة التحليلات التنفيذية', style: titleStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateFormatter.longDate(data.rangeFrom)} — '
            '${DateFormatter.longDate(data.rangeTo)}',
            style: baseStyle,
          ),
          pw.SizedBox(height: 16),
          pw.Text('المؤشرات الرئيسية', style: headingStyle),
          pw.SizedBox(height: 8),
          _pdfKpiTable(data, baseStyle, boldFont),
          pw.SizedBox(height: 20),
          pw.Text('تقدّم المشاريع', style: headingStyle),
          pw.SizedBox(height: 8),
          _pdfProjectProgressTable(data, baseStyle, boldFont),
          pw.SizedBox(height: 20),
          pw.Text('توزيع حالات المهام', style: headingStyle),
          pw.SizedBox(height: 8),
          _pdfTaskDistributionTable(data, baseStyle, boldFont),
          pw.SizedBox(height: 20),
          pw.Text('اتجاه الحضور اليومي', style: headingStyle),
          pw.SizedBox(height: 8),
          _pdfAttendanceTable(data, baseStyle, boldFont),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfKpiTable(
    AnalyticsData data,
    pw.TextStyle baseStyle,
    pw.Font boldFont,
  ) {
    final List<List<String>> rows = <List<String>>[
      <String>['المشاريع النشطة', '${data.activeProjectsCount}'],
      <String>[
        'متوسط نسبة الإنجاز',
        NumberFormatter.percent(data.averageProgressPercent / 100),
      ],
      <String>['مهام مفتوحة', '${data.totalOpenTasksCount}'],
      <String>['ملاحظات مفتوحة', '${data.totalOpenPunchItemsCount}'],
      <String>[
        'متوسط نسبة حضور اليوم',
        NumberFormatter.percent(data.averageTodayAttendanceRate),
      ],
      <String>['معدات قيد الصيانة', '${data.equipmentInMaintenanceCount}'],
    ];
    return _pdfTable(
      headers: const <String>['المؤشر', 'القيمة'],
      rows: rows,
      baseStyle: baseStyle,
      boldFont: boldFont,
    );
  }

  pw.Widget _pdfProjectProgressTable(
    AnalyticsData data,
    pw.TextStyle baseStyle,
    pw.Font boldFont,
  ) {
    final List<List<String>> rows = data.projectProgressList
        .map(
          (MapEntry<Project, double> e) => <String>[
            e.key.nameAr ?? e.key.name,
            '${e.value.toStringAsFixed(0)}%',
          ],
        )
        .toList(growable: false);
    return _pdfTable(
      headers: const <String>['المشروع', 'نسبة الإنجاز'],
      rows: rows,
      baseStyle: baseStyle,
      boldFont: boldFont,
    );
  }

  pw.Widget _pdfTaskDistributionTable(
    AnalyticsData data,
    pw.TextStyle baseStyle,
    pw.Font boldFont,
  ) {
    final Map<TaskStatus, int> distribution = data.taskStatusDistribution;
    final List<List<String>> rows = distribution.entries
        .map(
          (MapEntry<TaskStatus, int> e) =>
              <String>[_taskStatusArabicLabel(e.key), '${e.value}'],
        )
        .toList(growable: false);
    return _pdfTable(
      headers: const <String>['الحالة', 'العدد'],
      rows: rows,
      baseStyle: baseStyle,
      boldFont: boldFont,
    );
  }

  /// تسمية عربية لحالة مهمة — نفس التسميات المستخدمة في
  /// `TaskStatusChip`/`task_distribution_chart.dart`، مُعاد تعريفها
  /// هنا محلياً (بلا اعتماد على `Flutter Widgets`) لأن الكوبت لا يستورد
  /// أي ملف ودجات مباشرة.
  String _taskStatusArabicLabel(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => 'قائمة الانتظار',
      TaskStatus.inProgress => 'قيد التنفيذ',
      TaskStatus.review => 'قيد المراجعة',
      TaskStatus.done => 'مكتملة',
      TaskStatus.blocked => 'معلّقة',
    };
  }

  pw.Widget _pdfAttendanceTable(
    AnalyticsData data,
    pw.TextStyle baseStyle,
    pw.Font boldFont,
  ) {
    final List<List<String>> rows = data.attendanceTrend
        .map(
          (AttendanceTrendPoint p) => <String>[
            DateFormatter.shortDate(p.date),
            '${p.presentCount}',
          ],
        )
        .toList(growable: false);
    return _pdfTable(
      headers: const <String>['التاريخ', 'عدد الحاضرين'],
      rows: rows,
      baseStyle: baseStyle,
      boldFont: boldFont,
    );
  }

  pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.TextStyle baseStyle,
    required pw.Font boldFont,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      cellStyle: baseStyle,
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
      cellAlignment: pw.Alignment.centerRight,
      headerAlignment: pw.Alignment.centerRight,
      border: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}

/// حزمة داخلية بحتة لنقل نتائج [AnalyticsCubit._loadProjectAggregates]
/// — لا تُصدَّر خارج هذا الملف، ولا علاقة لها بـ [AnalyticsData] نفسها
/// (تُستهلَك فقط لبناء [AnalyticsData] الفعلية في [AnalyticsCubit.loadInitial]/
/// [AnalyticsCubit.refresh]).
class _AggregatedProjectData {
  const _AggregatedProjectData({
    required this.summaries,
    required this.tasksByProjectId,
    required this.attendanceByProjectId,
  });

  final Map<String, ProjectAnalyticsSummary> summaries;
  final Map<String, List<Task>> tasksByProjectId;
  final Map<String, List<AttendanceRecord>> attendanceByProjectId;
}
