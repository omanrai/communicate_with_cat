import 'dart:developer';

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
    log("HomeScreen - initState called");
    super.initState();
    try {
      _speech.initialize();
      log("Speech initialization successful");
    } catch (e) {
      log("Error initializing speech: $e");
    }
  }

  Future<void> _startListening() async {
    log("HomeScreen - _startListening called");
    if (!_isListening) {
      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            log("Speech Status Change: $status");
            if (status == "notListening") {
              log("Speech stopped listening");
            }
          },
          onError: (errorNotification) {
            log("Speech Error: ${errorNotification.errorMsg}");
            log("Error details: ${errorNotification.permanent}");
          },
        );
        log("Speech availability check result: $available");

        if (available) {
          setState(() {
            _isListening = true;
            log("State updated - listening started");
          });

          _speech.listen(
            onResult: (result) {
              log("Speech result received - Confidence: ${result.confidence}");
              log("Recognized words: ${result.recognizedWords}");
              setState(() {
                _spokenText = result.recognizedWords;
                log("State updated - spoken text: $_spokenText");
              });
            },
          );
        } else {
          log("Speech recognition not available on this device");
        }
      } catch (e) {
        log("Error in _startListening: $e");
      }
    }
  }

  Future<void> _stopListening() async {
    log("HomeScreen - _stopListening called");
    try {
      setState(() {
        _isListening = false;
        log("State updated - listening stopped");
      });

      await _speech.stop();
      log("Speech stopped successfully");

      if (_spokenText.isNotEmpty) {
        log("Initiating translation for text: $_spokenText");
        _translateToCatLanguage(_spokenText);
      } else {
        log("No text to translate - spoken text is empty");
      }
    } catch (e) {
      log("Error in _stopListening: $e");
    }
  }

  Future<void> _translateToCatLanguage(String inputText) async {
    log("HomeScreen - _translateToCatLanguage called with input: $inputText");
    const apiKey = "YOUR_OPENAI_API_KEY";
    const apiUrl = "https://api.openai.com/v1/completions";

    try {
      log("Preparing API request to OpenAI");
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
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

      log("API Response Status Code: ${response.statusCode}");
      log("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String catTranslation = data["choices"][0]["message"]["content"];
        log("Translation successful: $catTranslation");

        setState(() {
          _translatedText = catTranslation;
          log("State updated - translated text: $_translatedText");
        });

        _playCatSound();
      } else {
        log("API Error - Status Code: ${response.statusCode}");
        log("Error Response: ${response.body}");

        setState(() {
          _translatedText = "Translation failed!";
          log("State updated - translation failure message set");
        });
      }
    } catch (e) {
      log("Error in _translateToCatLanguage: $e");
      setState(() {
        _translatedText = "Translation error: $e";
      });
    }
  }

  Future<void> _playCatSound() async {
    log("HomeScreen - _playCatSound called");
    try {
      await _audioPlayer.play(AssetSource('meow.mp3'));
      log("Cat sound played successfully");
    } catch (e) {
      log("Error playing cat sound: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    log("HomeScreen - build called. isListening: $_isListening");
    return Scaffold(
      appBar: AppBar(
        title: Text("Communicate with Cat"),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
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
            AnimatedOpacity(
              opacity: _isListening ? 0.0 : 1.0,
              duration: Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: _isListening ? null : _startListening,
                child: Text("Start Speaking"),
              ),
            ),
            if (_isListening)
              ElevatedButton(
                onPressed: _stopListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text("Stop Listening"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    log("HomeScreen - dispose called");
    try {
      _audioPlayer.dispose();
      log("AudioPlayer disposed successfully");
    } catch (e) {
      log("Error disposing AudioPlayer: $e");
    }
    super.dispose();
  }
}
