import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:money_tracker/repository/screen/splash_screen.dart';
import 'package:money_tracker/common/color/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import permission_handler for runtime permission

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
  );
  usePathUrlStrategy();
  runApp(const MyApp());
}
final supabase  = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Quicksand',
        primaryColor: Coloors.blueDark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
