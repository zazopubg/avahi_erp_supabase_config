import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/api_constants.dart';
import '../../../../domain/entities/field_report.dart';
import '../../../dto/field_report_dto.dart';
import 'realtime_manager.dart';

/// يبث تغييرات (إنشاء/تحديث) جدول `public.field_reports` لحظياً ضمن
/// مشروع محدد — يُستخدم لتحديث حالة تقرير في واجهة `features/field_reports/`
/// (Prompt 17) فور اعتماده/رفضه دون الحاجة لإعادة الجلب اليدوي.
///
/// ⚠️ تُغلق كل الاشتراكات الفرعية المُنشأة من [watchProjectReports]
/// تلقائياً عند إغلاق [StreamController] الخاص بها (عند عدم وجود
/// مستمعين)؛ القناة نفسها في [RealtimeManager] تبقى مفتوحة ومُعاد
/// استخدامها لمشتركين جدد بنفس المشروع حتى استدعاء `disposeAll`.
class ReportSubscription {
  ReportSubscription({RealtimeManager? realtimeManager})
      : _realtimeManager = realtimeManager ?? RealtimeManager();

  final RealtimeManager _realtimeManager;

  Stream<FieldReport> watchProjectReports(String projectId) {
    final StreamController<FieldReport> controller = StreamController<FieldReport>.broadcast();
    controller.onCancel = controller.close;
    final String channelName = 'field_reports:project_id=eq.$projectId';

    _realtimeManager.channelFor(channelName, (sb.RealtimeChannel channel) {
      return channel
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.insert,
            schema: 'public',
            table: ApiConstants.tableFieldReports,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (sb.PostgresChangePayload payload) {
              controller.add(FieldReportDto.fromJson(payload.newRecord).toEntity());
            },
          )
          .onPostgresChanges(
            event: sb.PostgresChangeEvent.update,
            schema: 'public',
            table: ApiConstants.tableFieldReports,
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (sb.PostgresChangePayload payload) {
              controller.add(FieldReportDto.fromJson(payload.newRecord).toEntity());
            },
          );
    });

    return controller.stream;
  }
}
