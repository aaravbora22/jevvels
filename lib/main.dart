import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jevvels/authentication/data/datasources/supabase_auth_datasource.dart';
import 'package:jevvels/authentication/data/repositories/auth_respository_impl.dart';
import 'package:jevvels/authentication/domain/usecases/sign_in.dart';
import 'package:jevvels/authentication/domain/usecases/sign_up.dart';
import 'package:jevvels/authentication/domain/usecases/sign_out.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_bloc.dart';
import 'package:jevvels/authentication/presentation/pages/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jevvels/new_entry/supabase_powersync_images.dart';
import 'package:jevvels/new_entry/supabase_storage_adapter';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'powersync/powersync_connector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Load env and init Supabase
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 2️⃣ Open & initialize your PowerSync DB
  await openPowerSyncDatabase();

  // 3️⃣ Create, init & start watching your attachments queue
  final remoteStorage = SupabaseStorageAdapter('images');
  final attachmentQueue = AttachmentSyncQueue(db, remoteStorage);
  await attachmentQueue.init();
  attachmentQueue.watchIds(fileExtension: 'jpg');

  // 4️⃣ Listen for auth changes to connect/disconnect PowerSync
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    if (event == AuthChangeEvent.signedIn) {
      db.connect(connector: MyBackendConnector(db));
    } else if (event == AuthChangeEvent.signedOut) {
      await db.disconnectAndClear();
    }
    // tokenRefreshed is handled in MyBackendConnector
  });

  // 5️⃣ Wire up your auth BLoC and run the app
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
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Main Font',
          textTheme: TextTheme(
            bodyMedium: TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
