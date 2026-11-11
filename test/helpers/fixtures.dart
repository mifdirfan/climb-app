import 'package:climbmy/models/crag.dart';
import 'package:climbmy/models/tick.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const testUser = User(
  id: 'user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

const cragBatuCaves = Crag(id: 'crag-1', name: 'Batu Caves', state: 'Selangor');
const cragBukitTabur = Crag(id: 'crag-2', name: 'Bukit Tabur', state: 'Selangor');

Tick tick({
  String id = 'tick-1',
  String routeId = 'route-1',
  String tickType = 'send',
  String routeName = 'Nyamuk',
  String grade = '6b',
  String? cragName = 'Batu Caves',
  String? sectorName = 'Damai Wall',
  DateTime? climbedAt,
}) {
  return Tick(
    id: id,
    userId: testUser.id,
    routeId: routeId,
    tickType: tickType,
    climbedAt: climbedAt ?? DateTime(2026, 11, 3),
    routeName: routeName,
    routeGrade: grade,
    cragName: cragName,
    sectorName: sectorName,
  );
}
