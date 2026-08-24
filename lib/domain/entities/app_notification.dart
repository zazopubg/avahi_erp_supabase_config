import 'package:equatable/equatable.dart';

import '../enums/notification_type.dart';
import '../enums/related_entity_type.dart';

/// إشعار داخل التطبيق لمستخدم محدد، مرتبط اختيارياً بكيان مصدر
/// الإشعار عبر [relatedEntityType]/[relatedEntityId]. مطابق لجدول
/// `public.notifications` (انظر `013_create_notifications.sql`
/// و`019_extend_notification_types.sql`). 🆕
///
/// ملاحظة: اسم الملف/الصف `AppNotification` (وليس `Notification`)
/// لتفادي التعارض مع صف `Notification` المدمج في مكتبة `dart:core`.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.title,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.relatedEntityType,
    this.relatedEntityId,
    this.readAt,
  });

  final String id;
  final String companyId;

  /// معرّف المستخدم (`auth.users.id`) المستلم للإشعار.
  final String userId;

  final String title;
  final String? body;
  final NotificationType type;

  /// نوع الكيان المرتبط بمصدر الإشعار، اختياري (العمود في قاعدة
  /// البيانات نص حر بلا قيد CHECK، لذا [RelatedEntityType] هنا
  /// اجتهاد لأمان النوع على مستوى Flutter فقط).
  final RelatedEntityType? relatedEntityType;

  final String? relatedEntityId;

  final bool isRead;
  final DateTime? readAt;

  final DateTime createdAt;

  AppNotification copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    RelatedEntityType? relatedEntityType,
    String? relatedEntityId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        userId,
        title,
        body,
        type,
        relatedEntityType,
        relatedEntityId,
        isRead,
        readAt,
        createdAt,
      ];
}
