import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  // This is the Flutter equivalent of the web app's entry point.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(
      const _StartupErrorApp(
        message:
            'ไม่พบการตั้งค่า Supabase โปรดรันแอปด้วย --dart-define-from-file=config.json',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: true),
      debug: false,
    );
    runApp(const MyApp());
  } on Exception {
    runApp(
      const _StartupErrorApp(
        message: 'เริ่มต้นบริการ Supabase ไม่สำเร็จ โปรดตรวจสอบการตั้งค่า',
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FlashDeck',
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ))),
  );
}
