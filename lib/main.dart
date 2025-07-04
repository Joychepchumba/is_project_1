import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:is_project_1/pages/login_page.dart';
import 'package:is_project_1/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadEnv();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Set Mapbox Access Token
    final mapboxToken = dotenv.env["MAPBOX_ACCESS_TOKEN"];
    if (mapboxToken == null || mapboxToken.isEmpty) {
      throw Exception('MAPBOX_ACCESS_TOKEN is missing or empty in .env');
    }
    MapboxOptions.setAccessToken(mapboxToken);

    // Initialize Supabase
    final supabaseUrl = dotenv.env["SUPABASE_URL"];
    final supabaseAnonKey = dotenv.env["SUPABASE_ANON_KEY"];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is missing or empty in .env');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is missing or empty in .env');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    print('Supabase and Mapbox initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(), // your MapPage should render the map here
    );
  }
}
