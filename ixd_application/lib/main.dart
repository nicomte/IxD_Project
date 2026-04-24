import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: ArduinoDemo()));

class ArduinoDemo extends StatefulWidget {
  @override
  State<ArduinoDemo> createState() => _ArduinoDemoState();
}

class _ArduinoDemoState extends State<ArduinoDemo> {
  String _temp     = "—";
  String _humi     = "—";
  String _moisture = "—";
  String _uv       = "—";

  @override
  void initState() {
    super.initState();
    _readSerial();
  }

  void _readSerial() async {
    // MAC:
    // final file = File('/dev/cu.usbmodem1301');
    // Linux:
    final file = File('/dev/ttyACM0');
    final stream = file.openRead();
    final lines = stream.transform(utf8.decoder).transform(LineSplitter());

    await for (final line in lines) {
      try {
        final json = jsonDecode(line);
        setState(() {
          _temp     = json['temp'].toString();
          _humi     = json['humi'].toString();
          _moisture = json['moisture'].toString();
          _uv       = json['uv'].toString();
        });
      } catch (_) {
        // skip malformed lines
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Plant Dashboard")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Temperature: $_temp °C",  style: TextStyle(fontSize: 24)),
            SizedBox(height: 12),
            Text("Humidity:    $_humi %",   style: TextStyle(fontSize: 24)),
            SizedBox(height: 12),
            Text("Moisture:    $_moisture", style: TextStyle(fontSize: 24)),
            SizedBox(height: 12),
            Text("UV:          $_uv",       style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}