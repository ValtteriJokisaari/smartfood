import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/signin.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  String themeMode = prefs.getString('themeMode') ?? 'system';

  runApp(MyApp(themeNotifier: ThemeNotifier(themeMode)));
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier(String initialMode)
      : _themeMode = _getThemeMode(initialMode);

  ThemeMode get themeMode => _themeMode;

  void setTheme(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
    _themeMode = _getThemeMode(mode);
    notifyListeners(); // Notify app to rebuild with new theme
  }

  static ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const MyApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: "SmartFood",
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeNotifier.themeMode,
          initialRoute: "/",
          routes: {
            "/": (context) => const SignInScreen(),
            "/home": (context) => const Home(),
          },
        );
      },
    );
  }
}
