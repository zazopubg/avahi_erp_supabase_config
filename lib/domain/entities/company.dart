import 'package:equatable/equatable.dart';

/// الشركة/المستأجر (Tenant) الجذري في نظام Avahi متعدد المستأجرين.
/// مطابق لجدول `public.companies` (انظر `001_create_companies.sql`).
///
/// ⚠️ Dart نقي 100%: لا استيراد لأي شيء من Supabase أو Flutter. لا
/// يحتوي أي منطق تحقق (Validation) — ذلك من مسؤولية `domain/validators/`
/// في خطوة لاحقة (Prompt 06).
class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.slug,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.nameAr,
    this.logoUrl,
    this.address,
    this.phone,
  });

  /// المعرّف الفريد (UUID) للشركة.
  final String id;

  /// اسم الشركة بالإنجليزية (أو اللغة الأساسية).
  final String name;

  /// اسم الشركة بالعربية، اختياري.
  final String? nameAr;

  /// معرّف نصي فريد مستخدم في الروابط/الاستضافة الفرعية.
  final String slug;

  final String? logoUrl;
  final String? address;
  final String? phone;

  /// المنطقة الزمنية للشركة (افتراضياً `Asia/Baghdad`).
  final String timezone;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? slug,
    String? logoUrl,
    String? address,
    String? phone,
    String? timezone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        nameAr,
        slug,
        logoUrl,
        address,
        phone,
        timezone,
        isActive,
        createdAt,
        updatedAt,
      ];
}
