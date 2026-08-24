import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/entities/site_photo.dart';

/// حالة `ReportFormCubit` الكاملة — Union Type مكتوب يدوياً (`sealed
/// class` + تفريغ أنماط `switch`)، بنفس نمط `AttendanceState`/`TasksState`.
///
/// هذا الـ Cubit يقود **كل** شاشات جانب "العامل الميداني" من الميزة
/// (`mobile/*`): تعبئة/تحرير مسوّدة تقرير مع حفظ تلقائي (`report_form_screen.dart`)،
/// قائمة المسوّدات (`report_drafts_screen.dart`)، كل تقاريري
/// (`my_reports_screen.dart`)، المعاينة النهائية (`report_preview_screen.dart`)،
/// والتوقيع الرقمي المزدوج ثم التقديم (`report_signature_screen.dart`) —
/// كل شاشات هذه القائمة تشترك نفس نسخة [ReportFormCubit] (`BlocProvider`
/// واحد على مستوى `field_reports_screen.dart` للفرع الهاتفي، ينتقل معها
/// عبر `Navigator.push` بين الشاشات الفرعية)، بنفس فلسفة `AttendanceCubit`.
sealed class ReportFormState {
  const ReportFormState();

  T when<T>({
    required T Function() loading,
    required T Function(ReportFormData data) ready,
    required T Function(Failure failure) error,
  }) {
    final ReportFormState state = this;
    return switch (state) {
      ReportFormLoading() => loading(),
      ReportFormReady(:final data) => ready(data),
      ReportFormError(:final failure) => error(failure),
    };
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? loading,
    T Function(ReportFormData data)? ready,
    T Function(Failure failure)? error,
  }) {
    return when<T>(
      loading: loading ?? orElse,
      ready: ready ?? (_) => orElse(),
      error: error ?? (_) => orElse(),
    );
  }

  ReportFormData? get dataOrNull =>
      maybeWhen<ReportFormData?>(orElse: () => null, ready: (ReportFormData d) => d);
}

final class ReportFormLoading extends ReportFormState {
  const ReportFormLoading();
}

final class ReportFormReady extends ReportFormState {
  const ReportFormReady(this.data);

  final ReportFormData data;
}

final class ReportFormError extends ReportFormState {
  const ReportFormError(this.failure);

  final Failure failure;
}

/// حزمة بيانات ميزة نموذج التقرير المجمّعة — يحملها [ReportFormReady] وحدها.
class ReportFormData {
  const ReportFormData({
    required this.currentUser,
    required this.project,
    required this.report,
    this.photos = const <SitePhoto>[],
    this.myReports = const <FieldReport>[],
    this.isSaving = false,
    this.isWeatherLoading = false,
    this.weatherError,
    this.isUploadingPhoto = false,
    this.isSigningAndSubmitting = false,
    this.isMyReportsLoading = false,
  });

  final AppUser currentUser;
  final Project project;

  /// التقرير قيد التحرير حالياً — `report_form_screen.dart`/
  /// `report_preview_screen.dart`/`report_signature_screen.dart` الثلاثة
  /// تعمل جميعها على نفس الكائن، وتتحدث معاً فور أي تغيير.
  final FieldReport report;

  /// صور مرفقة بـ [report] (`report_photo_attach.dart`) — عبر
  /// `IPhotoRepository` مباشرة (`RelatedEntityType.fieldReport`).
  final List<SitePhoto> photos;

  /// كل تقارير المستخدم الحالي ضمن [project] — `my_reports_screen.dart`
  /// (كل الحالات) و`report_drafts_screen.dart` (تُصفَّى محلياً بـ
  /// `draftReports` أدناه لعرض المسوّدات فقط).
  final List<FieldReport> myReports;

  /// جارٍ حفظ مسوّدة تلقائياً (Debounce) — `report_form_screen.dart`
  /// يعرض مؤشراً صغيراً بدل قفل الشاشة بالكامل.
  final bool isSaving;

  final bool isWeatherLoading;

  /// رسالة خطأ تعبئة الطقس التلقائية (لا تمنع التعديل اليدوي) —
  /// `weather_selector.dart`.
  final String? weatherError;

  final bool isUploadingPhoto;

  /// جارٍ رفع التوقيع/التوقيعين ثم استدعاء `sign_report_usecase` ثم
  /// `submit_report_usecase` معاً — `report_signature_screen.dart`.
  final bool isSigningAndSubmitting;

  final bool isMyReportsLoading;

  /// مسوّدات [myReports] فقط، مرتّبة تنازلياً حسب تاريخ التقرير —
  /// `report_drafts_screen.dart`.
  List<FieldReport> get draftReports => myReports
      .where((FieldReport r) => r.status.isDraft)
      .toList(growable: false)
    ..sort((FieldReport a, FieldReport b) => b.reportDate.compareTo(a.reportDate));

  ReportFormData copyWith({
    AppUser? currentUser,
    Project? project,
    FieldReport? report,
    List<SitePhoto>? photos,
    List<FieldReport>? myReports,
    bool? isSaving,
    bool? isWeatherLoading,
    String? weatherError,
    bool clearWeatherError = false,
    bool? isUploadingPhoto,
    bool? isSigningAndSubmitting,
    bool? isMyReportsLoading,
  }) {
    return ReportFormData(
      currentUser: currentUser ?? this.currentUser,
      project: project ?? this.project,
      report: report ?? this.report,
      photos: photos ?? this.photos,
      myReports: myReports ?? this.myReports,
      isSaving: isSaving ?? this.isSaving,
      isWeatherLoading: isWeatherLoading ?? this.isWeatherLoading,
      weatherError: clearWeatherError ? null : (weatherError ?? this.weatherError),
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      isSigningAndSubmitting:
          isSigningAndSubmitting ?? this.isSigningAndSubmitting,
      isMyReportsLoading: isMyReportsLoading ?? this.isMyReportsLoading,
    );
  }
}
