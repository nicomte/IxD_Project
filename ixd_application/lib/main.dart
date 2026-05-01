import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
  //  _readSerial();
    _testData();
  }

  void _testData() {
  setState(() {
    _temperature = 22.5;
    _humidity = 55.0;
    _moisture = 48.0;
    _uv = 65.0;
  });
}


/* for testing
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
  } */

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
                        const SizedBox(width: 16),
                        const AnimatedPlantWidget(size: 150),
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

class AnimatedPlantWidget extends StatefulWidget {
  const AnimatedPlantWidget({super.key, this.size = 80});

  final double size;

  @override
  State<AnimatedPlantWidget> createState() => _AnimatedPlantWidgetState();
}

class _AnimatedPlantWidgetState extends State<AnimatedPlantWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PlantPainter(animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final double animationValue;

  _PlantPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final potTop = size.height * 0.65;

    // Hintergrund (transparent bleibt, Canvas default)
    // Pot
    final potWidth = size.width * 0.5;
    final potHeight = size.height * 0.2;
    final potX = centerX - potWidth / 2;
    final potY = potTop;

    final bob = math.sin(animationValue * 2 * math.pi * 0.8) * 2;

    paint.color = const Color(0xFFA6592C);
    canvas.drawRect(
      Rect.fromLTWH(potX, potY + bob, potWidth, potHeight),
      paint,
    );

    paint.color = const Color(0xFF7C3E1C);
    canvas.drawRect(
      Rect.fromLTWH(potX, potY + potHeight - 6 + bob, potWidth, 6),
      paint,
    );

    paint.color = const Color(0xFFCF906F);
    canvas.drawRect(
      Rect.fromLTWH(potX + 6, potY - 8 + bob, potWidth - 12, 8),
      paint,
    );

    final stemHeight = size.height * 0.5;
    final sway = math.sin(animationValue * 2 * math.pi * 0.6) * 10;
    final stretch = math.cos(animationValue * 2 * math.pi * 0.15) * 4;

    canvas.save();
    canvas.translate(centerX, potY);
    canvas.rotate(sway * 0.35 * math.pi / 180);
    paint.color = const Color(0xFF5B8A4D);
    canvas.drawRect(
      Rect.fromLTWH(-3, -stemHeight, 6, stemHeight + stretch),
      paint,
    );

    for (var i = 0; i < 4; i++) {
      final levelY = -i * 20.0 - 20;
      final wave = math.sin(animationValue * 2 * math.pi * 0.9 + i) * (10 - i * 1.2);
      _drawLeaf(canvas, paint, levelY, wave, i % 2 == 0);
    }
    canvas.restore();

    _drawFlower(
      canvas,
      Offset(centerX + sway * 0.35, potY - stemHeight - 10 + stretch * 0.2),
      sway,
      animationValue,
    );
  }

  void _drawLeaf(Canvas canvas, Paint paint, double y, double sway, bool flip) {
    final leafW = 30.0;
    final leafH = 10.0;
    final offset = flip ? -leafW : 0;
    paint.color = const Color(0xFF8AAE73);

    final path = Path()
      ..moveTo(offset.toDouble(), y)
      ..lineTo(offset + leafW, y - 5)
      ..lineTo(offset + leafW + sway * 0.5, y + leafH)
      ..lineTo(offset + sway * 0.5, y + leafH + 5)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawFlower(
      Canvas canvas, Offset center, double sway, double animationValue) {
    final paint = Paint();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sway * 0.35 * math.pi / 180);
    final pulse = ui.lerpDouble(0.9, 1.1, (math.sin(animationValue * 2 * math.pi * 0.12) * 0.5 + 0.5))!;
    paint.color = const Color(0xFFF8E4A0);

    for (var i = 0; i < 6; i++) {
      canvas.rotate(math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(12, 5),
          width: 18 * pulse,
          height: 8 * pulse,
        ),
        paint,
      );
    }

    paint.color = const Color(0xFFF15B5B);
    canvas.drawCircle(Offset.zero, 4 * pulse, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}