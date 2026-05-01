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

// ── Data ────────────────────────────────────────────────────────────────────

class PlantParams {
  final String label;
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;
  final double minMoisture;
  final double maxMoisture;
  final double minUvIndex;
  final double maxUvIndex;

  const PlantParams({
    required this.label,
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    required this.minMoisture,
    required this.maxMoisture,
    required this.minUvIndex,
    required this.maxUvIndex,
  });
}

String moistureLabel(double? value) {
  if (value == null) return '—';
  if (value < 150) return 'Very dry';
  if (value < 300) return 'Dry';
  if (value < 500) return 'Moist';
  if (value < 700) return 'Humid';
  if (value < 950) return 'Wet';
  return 'Overwatered';
}

const List<PlantParams> plantParamsList = [
  PlantParams(
    label: 'Cactus',
    minTemperature: 18, maxTemperature: 35,
    minHumidity: 10,    maxHumidity: 30,
    minMoisture: 5,     maxMoisture: 20,
    minUvIndex: 8,      maxUvIndex: 11,
  ),
  PlantParams(
    label: 'Fern',
    minTemperature: 15, maxTemperature: 24,
    minHumidity: 60,    maxHumidity: 90,
    minMoisture: 50,    maxMoisture: 80,
    minUvIndex: 1,      maxUvIndex: 3,
  ),
  PlantParams(
    label: 'Basil',
    minTemperature: 20, maxTemperature: 30,
    minHumidity: 40,    maxHumidity: 70,
    minMoisture: 30,    maxMoisture: 60,
    minUvIndex: 3,      maxUvIndex: 6,
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final String plantName;
  const DashboardScreen({super.key, required this.plantName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── Mutable state: only sensor readings + connection ──
  double? _temperature;
  double? _humidity;
  double? _moisture;
  double? _uv;

  @override
  void initState() {
    super.initState();
    _readSerial();
  }

  void _readSerial() async {
    try {
      final serialPort = File('/dev/ttyACM0');

      final stream = serialPort.openRead();
      final lines = stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in lines) {
        try {
          final json = jsonDecode(line);
          
          setState(() {
            _temperature = (json['temp'] as num?)?.toDouble();
            _humidity    = (json['humi'] as num?)?.toDouble();
            _moisture    = (json['moisture'] as num?)?.toDouble();
            _uv          = (json['uv'] as num?)?.toDouble();
          });
        } catch (_) {}
      }
    } catch (e) {
      print("Serial Port not found");
    }
  }

  String _fmt(double? v, String unit) =>
      v == null ? '—' : '${v.toStringAsFixed(0)}$unit';

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 12),

                // Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Hi, I'm ${widget.plantName}",
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ),
                    const Text('🪴', style: TextStyle(fontSize: 40)),
                  ],
                ),

                const Divider(color: Colors.red, thickness: 2),
                const SizedBox(height: 12),

                // Main content: sensor grid + plant info panel side by side
                LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  final sensorGrid = GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.6 : 1.2,
                    children: [
                      StatusCard(
                        title: 'Humidity',
                        icon: '≈',
                        value: _fmt(_humidity, '%'),
                        color: const Color(0xFFFFA726),
                      ),
                      StatusCard(
                        title: 'UV Index',
                        icon: '☀',
                        value: _fmt(_uv, ''),
                        color: const Color(0xFFFFF176),
                      ),
                      StatusCard(
                        title: 'Moisture',
                        icon: '💧',
                        value: moistureLabel(_moisture),
                        color: const Color(0xFF66BB6A),
                      ),
                      StatusCard(
                        title: 'Temperature',
                        icon: '🌡',
                        value: _fmt(_temperature, '°C'),
                        color: const Color(0xFFF8BBD0),
                      ),
                    ],
                  );

                  // Small cards listing each PlantParams entry
                  final plantInfoPanel = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plant profiles',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      const SizedBox(height: 8),
                      ...plantParamsList.map((p) => PlantInfoCard(params: p)),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: sensorGrid),
                        const SizedBox(width: 16),
                        SizedBox(width: 180, child: plantInfoPanel),
                      ],
                    );
                  }

                  return Column(children: [
                    sensorGrid,
                    const SizedBox(height: 16),
                    plantInfoPanel,
                  ]);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stateless widgets ────────────────────────────────────────────────────────

class StatusCard extends StatelessWidget {
  final String title;
  final String icon;
  final String value;
  final Color color;

  const StatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
            const SizedBox(width: 6),
            Text(icon, style: const TextStyle(fontSize: 18)),
          ]),
            Expanded(
              child: Center(
                child: Text(value, style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                )),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small card showing the preferred ranges for one PlantParams entry.
class PlantInfoCard extends StatelessWidget {
  final PlantParams params;
  const PlantInfoCard({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(params.label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          _row('🌡', '${params.minTemperature.toInt()}–${params.maxTemperature.toInt()}°C'),
          _row('≈',  '${params.minHumidity.toInt()}–${params.maxHumidity.toInt()}%'),
          _row('💧', '${params.minMoisture.toInt()}–${params.maxMoisture.toInt()}%'),
          _row('☀',  '${params.minUvIndex.toInt()}–${params.maxUvIndex.toInt()} UV'),
        ],
      ),
    );
  }

  Widget _row(String icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 11, color: Colors.black54)),
        ]),
      );
}