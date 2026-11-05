import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_screen.dart';
import 'main_screen.dart';

void main() => runApp(const SillyApp());

class SillyApp extends StatelessWidget {
  const SillyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final prefs = snapshot.data!;
          final key = prefs.getString('openrouter_api_key');
          return (key != null && key.isNotEmpty) ? const MainScreen() : const SetupScreen();
        },
      ),
    );
  }
}