import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const PlantBuddyApp());

class PlantBuddyApp extends StatelessWidget {
  const PlantBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const DashboardScreen(plantName: 'Basilikum'),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String plantName;

  const DashboardScreen({super.key, required this.plantName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double? _temperature;
  double? _humidity;
  double? _moisture;
  double? _uv;
  DateTime _lastUpdate = DateTime.now();
  DateTime? _lastWatering;
  bool _connected = false;
  String _connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _readSerial();
  }

  void _readSerial() async {
    try {
      // MAC:
      // final file = File('/dev/cu.usbmodem1301');
      // Linux:
      final file = File('/dev/ttyACM0');

      if (!await file.exists()) {
        setState(() {
          _connectionStatus = 'Arduino not found';
          _connected = false;
        });
        return;
      }

      final stream = file.openRead();
      final lines = stream.transform(utf8.decoder).transform(const LineSplitter());

      setState(() {
        _connected = true;
        _connectionStatus = 'Connected';
      });

      await for (final line in lines) {
        try {
          final json = jsonDecode(line);
          setState(() {
            _temperature = (json['temp'] as num?)?.toDouble();
            _humidity = (json['humi'] as num?)?.toDouble();
            _moisture = (json['moisture'] as num?)?.toDouble();
            _uv = (json['uv'] as num?)?.toDouble();
            _lastUpdate = DateTime.now();
          });
        } catch (_) {
          // skip malformed lines
        }
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection error';
        _connected = false;
      });
    }
  }

  String get _moodMessage {
    if (_humidity == null || _moisture == null || _temperature == null) {
      return "Waiting for sensor data...";
    }
    if (_moisture! < 30) return "I'm thirsty, please water me!";
    if (_humidity! < 30) return "The air is too dry...";
    if (_temperature! > 35) return "It's too hot here!";
    if (_temperature! < 15) return "Brrr, it's cold!";
    if (_uv != null && _uv! < 20) return "I need more sunlight!";
    return "I'm very happy right now!";
  }

  Color get _moodColor {
    if (_humidity == null || _moisture == null || _temperature == null) {
      return Colors.grey;
    }
    if (_moisture! < 30 || _temperature! > 35 || _temperature! < 15) {
      return Colors.orange;
    }
    return const Color(0xFF4CAF50);
  }

  String _formatValue(double? value, String unit) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(0)}$unit';
  }

  Mood _moodFor(double? value, double minOk, double maxOk) {
    if (value == null) return Mood.neutral;
    if (value >= minOk && value <= maxOk) return Mood.happy;
    return Mood.sad;
  }

  String get _lastWateringText {
    if (_lastWatering == null) return 'unknown';
    final diff = DateTime.now().difference(_lastWatering!);
    if (diff.inHours < 1) return 'just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final days = diff.inDays;
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  void _markWatered() {
    setState(() {
      _lastWatering = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yy HH:mm').format(_lastUpdate);

    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(formattedDate),
                const SizedBox(height: 12),
                _buildGreeting(),
                const SizedBox(height: 8),
                _buildMoodLine(),
                const Divider(color: Colors.red, thickness: 2),
                const SizedBox(height: 12),
                _buildSectionTitle(),
                const SizedBox(height: 16),
                _buildStatusGrid(),
                const SizedBox(height: 16),
                _buildWaterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _connected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _connectionStatus,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            "Hi, I'm ${widget.plantName}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        const Text('🪴', style: TextStyle(fontSize: 40)),
      ],
    );
  }

  Widget _buildMoodLine() {
    return Row(
      children: [
        Flexible(
          child: Text(
            _moodMessage,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _moodColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: const [
        Text(
          'Here is the status of my home',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        SizedBox(width: 8),
        Text('🏠', style: TextStyle(fontSize: 24)),
      ],
    );
  }

  Widget _buildStatusGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final statusCards = [
          StatusCard(
            title: 'Humidity',
            icon: '≈',
            value: _formatValue(_humidity, '%'),
            color: const Color(0xFFFFA726),
            mood: _moodFor(_humidity, 40, 80),
          ),
          StatusCard(
            title: 'Sun-Level (UV)',
            icon: '☀',
            value: _formatValue(_uv, '%'),
            color: const Color(0xFF66BB6A),
            mood: _moodFor(_uv, 30, 90),
          ),
          StatusCard(
            title: 'Moisture',
            icon: '💧',
            value: _formatValue(_moisture, '%'),
            color: const Color(0xFF66BB6A),
            mood: _moodFor(_moisture, 40, 80),
          ),
          StatusCard(
            title: 'Temperature',
            icon: '🌡',
            value: _formatValue(_temperature, '°C'),
            color: const Color(0xFFF8BBD0),
            mood: _moodFor(_temperature, 18, 30),
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: statusCards,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: LastWateringCard(text: _lastWateringText),
              ),
            ],
          );
        }

        return Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: statusCards,
            ),
            const SizedBox(height: 16),
            LastWateringCard(text: _lastWateringText),
          ],
        );
      },
    );
  }

  Widget _buildWaterButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _markWatered,
        icon: const Text('💧', style: TextStyle(fontSize: 20)),
        label: const Text('I just watered!'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66BB6A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

enum Mood { happy, sad, neutral }

class StatusCard extends StatelessWidget {
  final String title;
  final String icon;
  final String value;
  final Color color;
  final Mood mood;

  const StatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(icon, style: const TextStyle(fontSize: 20)),
            ],
          ),
          Row(
            children: [
              MoodFace(mood: mood),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MoodFace extends StatelessWidget {
  final Mood mood;

  const MoodFace({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    String face;
    switch (mood) {
      case Mood.happy:
        face = '☺';
        break;
      case Mood.sad:
        face = '☹';
        break;
      case Mood.neutral:
        face = '◔';
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: Center(
        child: Text(
          face,
          style: const TextStyle(fontSize: 22, color: Colors.black87),
        ),
      ),
    );
  }
}

class LastWateringCard extends StatelessWidget {
  final String text;

  const LastWateringCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last watering:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}