import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Record _audioRecord;
  late AudioPlayer _audioPlayer;
  bool _isRecord = false;
  String? _audioPath;
  Duration _duration = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _audioRecord = Record();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
    _audioRecord.dispose();
    _timer.cancel(); // Cancel the timer to avoid memory leaks
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecord.hasPermission()) {
        await _audioRecord.start();
        setState(() {
          _isRecord = true;
        });
        _startTimer();
      }
    } catch (e) {
      print('Recording failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecord.stop();
      setState(() {
        _audioPath = path;
        _isRecord = false;
      });
      _stopTimer();
    } catch (e) {
      print('Recording failed: $e');
    }
  }

  Future<void> playRecording() async {
    Source url = UrlSource(_audioPath!);
    await _audioPlayer.play(url);
  }

  void _startTimer() {
    _duration = Duration.zero;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _duration = _duration + Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecord)
              Text(
                ' ${_formatDuration(_duration)}',
                style: TextStyle(fontSize: 20),
              ),
            FloatingActionButton(
              shape: CircleBorder(),
              onPressed: () {
                _isRecord ? _stopRecording() : _startRecording();
              },
              child: _isRecord ? Icon(Icons.stop) : Icon(Icons.mic),
            ),
            SizedBox(height: 20),
            if (!_isRecord && _audioPath != null)
              ElevatedButton(
                onPressed: playRecording,
                child: Text('Play recording'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
