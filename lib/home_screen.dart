import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = "Press the button and speak";
  String _translatedText = "Cat translation will appear here";
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _speech.initialize();
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print("Status: $status"),
        onError: (error) => print("Error: $error"),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _spokenText = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
    if (_spokenText.isNotEmpty) {
      _translateToCatLanguage(_spokenText);
    }
  }

  Future<void> _translateToCatLanguage(String inputText) async {
    const apiKey = "YOUR_OPENAI_API_KEY"; // Replace with your chatGPT API key
    const apiUrl = "https://api.openai.com/v1/completions";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        //put model version in which you want to translate from
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a cat that translates human speech into cat meows."
          },
          {"role": "user", "content": "Translate to cat language: $inputText"}
        ],
        "max_tokens": 20
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String catTranslation = data["choices"][0]["message"]["content"];
      setState(() {
        _translatedText = catTranslation;
      });
      _playCatSound();
    } else {
      setState(() {
        _translatedText = "Translation failed!";
      });
    }
  }

  Future<void> _playCatSound() async {
    await _audioPlayer
        .play(AssetSource('meow.mp3')); // Add a cat sound to your assets
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Communicate with Cat")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_spokenText, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(_translatedText,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? "Stop Listening" : "Start Speaking"),
            ),
          ],
        ),
      ),
    );
  }
}
