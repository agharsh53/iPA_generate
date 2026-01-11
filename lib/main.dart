import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:money_tracker/repository/screen/splash_screen.dart';
import 'package:money_tracker/common/color/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import permission_handler for runtime permission

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uckdhkxlivzdljvirtiu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVja2Roa3hsaXZ6ZGxqdmlydGl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MTE0NjgsImV4cCI6MjA4MzI4NzQ2OH0.-9eCXMKZOgTsHJNUKMExSLBrGzeFrJFrRSc-1QQ8-EU',
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
