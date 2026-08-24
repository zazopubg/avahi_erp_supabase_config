import '../../domain/entities/company.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.companies` (انظر
/// `001_create_companies.sql`) بأسماء أعمدة `snake_case` الحرفية.
class CompanyDto {
  const CompanyDto({
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

  final String id;
  final String name;
  final String? nameAr;
  final String slug;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CompanyDto.fromJson(Map<String, dynamic> json) {
    return CompanyDto(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      timezone: json['timezone'] as String,
      isActive: json['is_active'] as bool,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'slug': slug,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'timezone': timezone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج/التحديث (بدون `id`/`created_at`/`updated_at`،
  /// المُدارة من الخادم عبر `default gen_random_uuid()` وTrigger
  /// `set_updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'name': name,
      'name_ar': nameAr,
      'slug': slug,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'timezone': timezone,
      'is_active': isActive,
    };
  }

  Company toEntity() {
    return Company(
      id: id,
      name: name,
      nameAr: nameAr,
      slug: slug,
      logoUrl: logoUrl,
      address: address,
      phone: phone,
      timezone: timezone,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CompanyDto.fromEntity(Company entity) {
    return CompanyDto(
      id: entity.id,
      name: entity.name,
      nameAr: entity.nameAr,
      slug: entity.slug,
      logoUrl: entity.logoUrl,
      address: entity.address,
      phone: entity.phone,
      timezone: entity.timezone,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
