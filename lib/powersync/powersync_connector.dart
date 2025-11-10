import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powersync/powersync.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jevvels/powersync/schema.dart';

late final PowerSyncDatabase db;

/// postgres REsponse codes that cannot recover from by retrying.
final List<RegExp> fatalResponseCodes = [
  RegExp(r'^22...$'),
  RegExp(r'^23...$'),
  RegExp(r'^42501$'),
];

class MyBackendConnector extends PowerSyncBackendConnector {
  Future<void>? _refreshFuture;
  final PowerSyncDatabase db;
  MyBackendConnector(this.db);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    await _refreshFuture;
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      return null;
    }
    return PowerSyncCredentials(
      endpoint: dotenv.env['POWERSYNC_ENDPOINT'] ??
          'https://687b42e9084dcafd4bbe2461.powersync.journeyapps.com',
      token: jwt,
    );
  }

  @override
  void invalidateCredentials() {
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((response) => null, onError: (error) => null);
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }
    final rest = Supabase.instance.client.rest;
    try {
      for (var op in transaction.crud) {
        final table = rest.from(op.table);
        if (op.op == UpdateType.put) {
          var data = Map<String, dynamic>.of(op.opData!);
          data['id'] = op.id;
          await table.upsert(data);
        } else if (op.op == UpdateType.patch) {
          await table.update(op.opData!).eq('id', op.id);
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      if (e.code != null &&
          fatalResponseCodes.any((re) => re.hasMatch(e.code!))) {
        await transaction.complete();
      } else {
        rethrow;
      }
    }
  }
}

Future<String> getDatabasePath() async {
  final dir = await getApplicationSupportDirectory();
  final path = join(dir.path, 'powersync-demo.db');
  print('Database path: ' + path);
  return path;
}

Future<void> openPowerSyncDatabase() async {
  db = PowerSyncDatabase(schema: schema, path: await getDatabasePath());
  await db.initialize();
  await dotenv.load(fileName: '.env');
  db.connect(connector: MyBackendConnector(db));
}
