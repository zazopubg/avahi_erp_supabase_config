import 'package:avahi/data/sync/conflict/conflict_resolver.dart';
import 'package:avahi/data/sync/conflict/first_write_wins.dart';
import 'package:avahi/data/sync/conflict/last_write_wins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirstWriteWinsResolver — first_write_wins للحضور', () {
    const FirstWriteWinsResolver resolver = FirstWriteWinsResolver();

    test('يفضّل النسخة المحلية عندما كانت created_at المحلية أسبق', () {
      final ConflictResolution resolution = resolver.resolve(
        local: <String, dynamic>{
          'created_at': '2026-01-10T08:00:00.000Z',
        },
        remote: <String, dynamic>{
          'created_at': '2026-01-10T09:00:00.000Z',
        },
      );

      expect(resolution.outcome, ConflictOutcome.keepLocal);
    });

    test('يفضّل النسخة السحابية عندما كانت created_at السحابية أسبق', () {
      final ConflictResolution resolution = resolver.resolve(
        local: <String, dynamic>{
          'created_at': '2026-01-10T09:30:00.000Z',
        },
        remote: <String, dynamic>{
          'created_at': '2026-01-10T09:00:00.000Z',
        },
      );

      expect(resolution.outcome, ConflictOutcome.keepRemote);
    });

    test('يفضّل النسخة السحابية عند تساوي التوقيتين تماماً (حدّي، الآمن '
        'دوماً)', () {
      final ConflictResolution resolution = resolver.resolve(
        local: <String, dynamic>{
          'created_at': '2026-01-10T09:00:00.000Z',
        },
        remote: <String, dynamic>{
          'created_at': '2026-01-10T09:00:00.000Z',
        },
      );

      expect(resolution.outcome, ConflictOutcome.keepRemote);
    });

    test('يفضّل النسخة السحابية (الأكثر أماناً) عند تعذّر قراءة created_at '
        'من أي طرف', () {
      final ConflictResolution localMissing = resolver.resolve(
        local: <String, dynamic>{},
        remote: <String, dynamic>{'created_at': '2026-01-10T09:00:00.000Z'},
      );
      final ConflictResolution remoteMissing = resolver.resolve(
        local: <String, dynamic>{'created_at': '2026-01-10T09:00:00.000Z'},
        remote: <String, dynamic>{},
      );

      expect(localMissing.outcome, ConflictOutcome.keepRemote);
      expect(remoteMissing.outcome, ConflictOutcome.keepRemote);
    });
  });

  group('LastWriteWinsResolver — last_write_wins للمهام', () {
    const LastWriteWinsResolver resolver = LastWriteWinsResolver();

    test('يفضّل النسخة المحلية عندما كانت updated_at المحلية أحدث', () {
      final ConflictResolution resolution = resolver.resolve(
        local: <String, dynamic>{
          'updated_at': '2026-01-10T12:00:00.000Z',
        },
        remote: <String, dynamic>{
          'updated_at': '2026-01-10T09:00:00.000Z',
        },
      );

      expect(resolution.outcome, ConflictOutcome.keepLocal);
    });

    test('يفضّل النسخة السحابية عندما كانت updated_at السحابية أحدث', () {
      final ConflictResolution resolution = resolver.resolve(
        local: <String, dynamic>{
          'updated_at': '2026-01-10T09:00:00.000Z',
        },
        remote: <String, dynamic>{
          'updated_at': '2026-01-10T12:00:00.000Z',
        },
      );

      expect(resolution.outcome, ConflictOutcome.keepRemote);
    });

    test('يفضّل النسخة السحابية عند تساوي التوقيتين تماماً (حدّي)', () {
      final ConflictResolution resolution = resolver.resolve(
        local: <String, dynamic>{
          'updated_at': '2026-01-10T09:00:00.000Z',
        },
        remote: <String, dynamic>{
          'updated_at': '2026-01-10T09:00:00.000Z',
        },
      );

      expect(resolution.outcome, ConflictOutcome.keepRemote);
    });

    test('يفضّل النسخة السحابية عند تعذّر قراءة updated_at من أي طرف', () {
      final ConflictResolution localMissing = resolver.resolve(
        local: <String, dynamic>{},
        remote: <String, dynamic>{'updated_at': '2026-01-10T09:00:00.000Z'},
      );

      expect(localMissing.outcome, ConflictOutcome.keepRemote);
    });
  });
}
