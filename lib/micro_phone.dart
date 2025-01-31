import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart';
import 'home_screen2.dart';

class MicrophonePermissionScreen extends StatefulWidget {
  @override
  _MicrophonePermissionScreenState createState() =>
      _MicrophonePermissionScreenState();
}

class _MicrophonePermissionScreenState
    extends State<MicrophonePermissionScreen> {
  bool _isChecking = true;
  String _permissionStatus = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    log("Checking microphone permission status");
    try {
      var status = await Permission.microphone.status;
      setState(() {
        _isChecking = false;
        _permissionStatus = status.toString();
      });
      log("Current permission status: $status");

      if (status.isGranted) {
        _navigateToHome();
      }
    } catch (e) {
      log("Error checking permission: $e");
      setState(() {
        _isChecking = false;
        _permissionStatus = 'Error checking permission';
      });
    }
  }

  Future<void> _requestPermission() async {
    log("Requesting microphone permission");
    try {
      var status = await Permission.microphone.request();
      setState(() {
        _permissionStatus = status.toString();
      });
      log("Permission request result: $status");

      if (status.isGranted) {
        _navigateToHome();
      } else {
        _showSettingsDialog();
      }
    } catch (e) {
      log("Error requesting permission: $e");
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Microphone Permission Required'),
        content: Text(
          'This app needs microphone access to convert speech to text. '
          'Please enable it in settings.',
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Microphone Permission'),
        centerTitle: true,
      ),
      body: Center(
        child: _isChecking
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Microphone Permission Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'This app needs microphone access to convert your speech into cat language.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: Icon(Icons.mic),
                    label: Text('Grant Microphone Permission'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
