import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:thinking_orbs_flutter/thinking_orbs.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  String? _apiKey;
  String _status = 'Tap the orb to speak';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('openrouter_api_key');
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _speech.initialize();
  }

  Future<void> _listen() async {
    if (_isBusy || !_speech.isAvailable) return;
    setState(() => _status = 'Listening...');
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processQuery(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _processQuery(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isBusy = true; _status = 'Silly is thinking...'; });

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001', // Fast model
          'messages': [
            {'role': 'system', 'content': 'You are Silly, a helpful and friendly AI assistant. Keep responses concise and conversational.'},
            {'role': 'user', 'content': query},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        setState(() => _status = reply);
        await _tts.speak(reply);
      } else {
        setState(() => _status = 'Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Something went wrong.');
    } finally {
      setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Critical for dotted orb visibility
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The moving dotted orb (matches your picture)
              GestureDetector(
                onTap: _listen,
                child: ThinkingOrb(
                  state: OrbState.listening,
                  size: OrbSize.large,
                  theme: OrbTheme.dark, // Light dots on dark background
                  speed: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}