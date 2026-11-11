import 'package:climbmy/models/tick.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tick.fromJson', () {
    test('parses the logbook select shape (routes -> crags + sectors)', () {
      final t = Tick.fromJson({
        'id': 't1',
        'user_id': 'u1',
        'route_id': 'r1',
        'tick_type': 'flash',
        'video_url': 'https://youtu.be/abc',
        'climbed_at': '2026-11-03',
        'routes': {
          'name': 'Nyamuk',
          'grade': '6b',
          'route_type': 'sport',
          'crags': {'name': 'Batu Caves'},
          'sectors': {'name': 'Damai Wall'},
        },
      });

      expect(t.routeName, 'Nyamuk');
      expect(t.routeGrade, '6b');
      expect(t.cragName, 'Batu Caves');
      expect(t.sectorName, 'Damai Wall');
      expect(t.videoUrl, 'https://youtu.be/abc');
      expect(t.climbedAt, DateTime(2026, 11, 3));
    });

    test('resolves crag name when route has no sector', () {
      final t = Tick.fromJson({
        'id': 't1',
        'route_id': 'r1',
        'tick_type': 'send',
        'climbed_at': '2026-11-03',
        'routes': {'name': 'X', 'grade': '7a', 'crags': {'name': 'Bukit Tabur'}, 'sectors': null},
      });

      expect(t.cragName, 'Bukit Tabur');
      expect(t.sectorName, isNull);
    });

    test('still supports the legacy sectors -> crags nesting', () {
      final t = Tick.fromJson({
        'id': 't1',
        'route_id': 'r1',
        'tick_type': 'send',
        'routes': {
          'name': 'X',
          'sectors': {'name': 'S', 'crags': {'name': 'Legacy Crag'}},
        },
      });

      expect(t.cragName, 'Legacy Crag');
    });
  });

  group('Tick style helpers', () {
    Tick ofType(String type) => Tick(id: 'i', userId: 'u', routeId: 'r', tickType: type, climbedAt: DateTime(2026));

    test('redpoint (allowed by live DB constraint) counts as a clean send', () {
      expect(ofType('redpoint').isCleanSend, isTrue);
      expect(ofType('redpoint').styleDisplayName, 'Redpoint / Send');
    });

    test('project is not a clean send', () {
      expect(ofType('project').isCleanSend, isFalse);
    });

    test('toJson round-trips video_url', () {
      final json = ofType('send').copyWith(videoUrl: 'https://tiktok.com/x').toJson();
      expect(json['video_url'], 'https://tiktok.com/x');
    });
  });
}
