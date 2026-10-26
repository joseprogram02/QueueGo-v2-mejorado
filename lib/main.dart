import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
);

  runApp(const QueueGoApp());
}

class QueueGoApp extends StatelessWidget {
  const QueueGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QueueGo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const LoginScreen(),
    );
  }
}
