import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Android Emulator maps host localhost (127.0.0.1) to 10.0.2.2.
// Use 127.0.0.1 for Windows/Desktop/iOS Simulator.
const supabaseUrl = 'https://npbpyzoiphzfcjxfuniz.supabase.co';
const supabaseAnonKey = 'sb_publishable_8YafDV_-3X4fYY2EEAiL5Q_JuH7Ji41';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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

class ClimbMYApp extends StatelessWidget {
  const ClimbMYApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimbMY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ConnectionTestScreen(),
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