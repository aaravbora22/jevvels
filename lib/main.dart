import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jevvels/src/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jevvels/authentication/data/datasources/supabase_auth_datasource.dart';
import 'package:jevvels/authentication/data/repositories/auth_respository_impl.dart';
import 'package:jevvels/authentication/domain/usecases/sign_in.dart';
import 'package:jevvels/authentication/domain/usecases/sign_up.dart';
import 'package:jevvels/authentication/domain/usecases/sign_out.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_bloc.dart';

import 'powersync/powersync_connector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load env
  await dotenv.load(fileName: '.env');

  // 2. Init Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Open PowerSync DB
  await openPowerSyncDatabase();

  // // 🔥 One-time: wipe old attachment queue rows
  // await db.execute('DELETE FROM attachments_queue');
  // print('✅ attachments_queue cleared');

  // 4. Auth / connector wiring
  final auth = Supabase.instance.client.auth;

  if (auth.currentUser != null) {
    db.connect(connector: MyBackendConnector(db));
  }

  auth.onAuthStateChange.listen((data) async {
    final event = data.event;

    if (event == AuthChangeEvent.signedIn) {
      db.connect(connector: MyBackendConnector(db));
    } else if (event == AuthChangeEvent.signedOut) {
      await db.disconnectAndClear();
    }
  });

  // 5. Auth DI
  final datasource = SupabaseAuthDatasource();
  final repository = AuthRepositoryImpl(datasource);
  final signIn = SignIn(repository);
  final signUp = SignUp(repository);
  final signOut = SignOut(repository);

  runApp(
    MyApp(
      signIn: signIn,
      signUp: signUp,
      signOut: signOut,
    ),
  );
}


/// 🔧 One-time cleanup of stale attachment rows that used old filenames
Future<void> cleanupOldAttachments() async {
  // Optional: inspect what's there before deleting
  final rows = await db.execute(
    'SELECT id, filename, state FROM attachments_queue',
  );
  for (final row in rows) {
    print(
      '🧹 attachments_queue row -> '
      'id=${row['id']}, filename=${row['filename']}, state=${row['state']}',
    );
  }

  // ✅ Delete only "old-style" filenames (no bills/ or items/ prefix)
  await db.execute(
    "DELETE FROM attachments_queue "
    "WHERE filename NOT LIKE 'bills/%' AND filename NOT LIKE 'items/%'",
  );

  print('✅ Cleanup complete: removed old attachment queue entries');
}

class MyApp extends StatelessWidget {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;

  const MyApp({
    super.key,
    required this.signIn,
    required this.signUp,
    required this.signOut,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            signIn: signIn,
            signUp: signUp,
            signOut: signOut,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Jevvels',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Main Font',
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const JevvelsSplashScreen(),
      ),
    );
  }
}
