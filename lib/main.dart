import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/core/router/app_router.dart';

// Android Emulator maps host localhost (127.0.0.1) to 10.0.2.2.
// Use 127.0.0.1 for Windows/Desktop/iOS Simulator.


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Notice: .env file not loaded: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey, // ignore: deprecated_member_use
  );

  // Inspect and log initial session presence on startup
  final initialSession = Supabase.instance.client.auth.currentSession;
  final initialUser = Supabase.instance.client.auth.currentUser;
  if (initialSession != null && initialUser != null) {
    debugPrint('--> [AUTH:INIT] Initial session found: UID=${initialUser.id}, Email=${initialUser.email}');
  } else {
    debugPrint('--> [AUTH:INIT] No initial active session detected (Guest mode)');
  }

  // Globally monitor and log all authentication state transitions
  Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
    final event = authState.event;
    final session = authState.session;
    debugPrint('--> [AUTH:STREAM] AuthChangeEvent: $event | Active Session: ${session != null}');
    if (session != null) {
      debugPrint('    Session User: ${session.user.email} (UID: ${session.user.id})');
      debugPrint('    Expires At: ${session.expiresAt}');
    }

    if (event == AuthChangeEvent.signedIn) {
      debugPrint('--> [AUTH:STREAM] ✅ User signed in confirmed: ${session?.user.email}');
    } else if (event == AuthChangeEvent.signedOut) {
      debugPrint('--> [AUTH:STREAM] ℹ️ User signed out confirmed');
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      debugPrint('--> [AUTH:STREAM] 🔄 Access token refreshed');
    } else if (event == AuthChangeEvent.userUpdated) {
      debugPrint('--> [AUTH:STREAM] 👤 User profile/metadata updated');
    }
  });

  runApp(
    const ProviderScope(
      child: ClimbMYApp(),
    ),
  );
}

final cragsCountProvider = FutureProvider<int>((ref) async {
  final response = await Supabase.instance.client
      .from('crags')
      .select()
      .count(CountOption.exact);
  return response.count;
});

class ClimbMYApp extends ConsumerWidget {
  const ClimbMYApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ClimbMY',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

class ConnectionTestScreen extends ConsumerWidget {
  const ConnectionTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cragCountAsync = ref.watch(cragsCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ClimbMY - Stack Test')),
      body: Center(
        child: cragCountAsync.when(
          data: (count) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Connected to Local Supabase!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Total Crags in DB: $count'),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Connection Error: $err', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}