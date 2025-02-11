import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // Import flutter_dotenv
import 'firebase_options.dart';  // Import firebase_options.dart
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("Loading environment variables...");
  // Load environment variables before using them
  await dotenv.load(fileName: ".env");
  print("Environment variables loaded");

  // Print environment variables
  print("FIREBASE_API_KEY: ${dotenv.env['FIREBASE_API_KEY']}");
  print("FIREBASE_MESSAGING_SENDER_ID: ${dotenv.env['FIREBASE_MESSAGING_SENDER_ID']}");
  print("FIREBASE_PROJECT_ID: ${dotenv.env['FIREBASE_PROJECT_ID']}");
  print("FIREBASE_AUTH_DOMAIN: ${dotenv.env['FIREBASE_AUTH_DOMAIN']}");
  print("FIREBASE_STORAGE_BUCKET: ${dotenv.env['FIREBASE_STORAGE_BUCKET']}");
  print("FIREBASE_MEASUREMENT_ID: ${dotenv.env['FIREBASE_MEASUREMENT_ID']}");
  print("FIREBASE_APP_ID_ANDROID: ${dotenv.env['FIREBASE_APP_ID_ANDROID']}");
  print("FIREBASE_APP_ID_IOS: ${dotenv.env['FIREBASE_APP_ID_IOS']}");
  print("FIREBASE_IOS_BUNDLE_ID: ${dotenv.env['FIREBASE_IOS_BUNDLE_ID']}");
  print("FIREBASE_APP_ID_WEB: ${dotenv.env['FIREBASE_APP_ID_WEB']}");

  try {
    print("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,  // Use platform-specific options
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SmartFood",
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: "Poiret",
      ),
      home: BlocProvider(
        create: (context) => NavigationCubit(),
        child: const Home(), 
      ),
    );
  }
}

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void changePage(int index) => emit(index);
}
