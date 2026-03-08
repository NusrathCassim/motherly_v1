import 'package:flutter/material.dart';
import 'package:motherly_v1/models/growth_record_model.dart';
import 'package:motherly_v1/utils/growth_calculator.dart';

class GrowthChartWidget extends StatefulWidget {
  final List<GrowthRecord> records;
  final bool isSinhala;
  final String gender;

  const GrowthChartWidget({
    super.key,
    required this.records,
    required this.isSinhala,
    required this.gender,
  });

  @override
  State<GrowthChartWidget> createState() => _GrowthChartWidgetState();
}

class _GrowthChartWidgetState extends State<GrowthChartWidget> {
  static const double minWeight = 0;
  static const double maxWeight = 20;
  static const int maxAge = 24;

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildLegendItem(Colors.red, widget.isSinhala ? 'ඉතා අඩු' : 'Very Low'),
              _buildLegendItem(Colors.orange, widget.isSinhala ? 'අඩු' : 'Low'),
              _buildLegendItem(Colors.lightGreen, widget.isSinhala ? 'අවධානය' : 'At Risk'),
              _buildLegendItem(Colors.green, widget.isSinhala ? 'සාමාන්‍ය' : 'Normal'),
              _buildLegendItem(Colors.purple, widget.isSinhala ? 'අධික' : 'High'),
            ],
          ),
        ),

        // Chart
        Container(
          height: 300,
          margin: const EdgeInsets.all(16),
          child: CustomPaint(
            painter: _GrowthChartPainter(
              records: widget.records,
              gender: widget.gender,
            ),
            size: Size.infinite,
          ),
        ),

        // X-axis label
        Center(
          child: Text(
            widget.isSinhala ? 'වයස (මාස)' : 'Age (months)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Recent measurements
        _buildRecentMeasurements(),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeasurements() {
    if (widget.records.isEmpty) return const SizedBox();

    final sorted = [...widget.records]..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first;
    
    final status = GrowthCalculator.calculateWeightStatus(
      latest.weight,
      latest.ageInMonths,
      widget.gender,
    );
    final statusColor = GrowthCalculator.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isSinhala ? 'අවසන් මිනුම' : 'Latest Measurement',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${latest.ageInMonths} ${widget.isSinhala ? 'මාස' : 'months'}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMeasurementItem(
                icon: Icons.monitor_weight,
                label: widget.isSinhala ? 'බර' : 'Weight',
                value: '${latest.weight.toStringAsFixed(1)} kg',
                color: statusColor,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade300,
              ),
              _buildMeasurementItem(
                icon: Icons.health_and_safety,
                label: widget.isSinhala ? 'තත්ත්වය' : 'Status',
                value: GrowthCalculator.getStatusMessage(status, widget.isSinhala),
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              widget.isSinhala
                  ? 'තවමත් බර මිනුම් නැත'
                  : 'No weight measurements yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  final List<GrowthRecord> records;
  final String gender;

  _GrowthChartPainter({
    required this.records,
    required this.gender,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final sorted = [...records]..sort((a, b) => a.ageInMonths.compareTo(b.ageInMonths));
    
    // Draw grid
    _drawGrid(canvas, size);
    
    // Draw reference lines (WHO standards)
    _drawReferenceLines(canvas, size);
    
    // Draw data points and lines
    _drawGrowthLines(canvas, size, sorted);
    _drawDataPoints(canvas, size, sorted);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Horizontal grid lines (weight)
    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
      
      // Weight labels
      final weight = 20 - (i * 4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$weight kg',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - 10));
    }

    // Vertical grid lines (age)
    for (int i = 0; i <= 6; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
      
      // Age labels
      final age = i * 4;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$age',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 5, size.height + 5));
    }
  }

  void _drawReferenceLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw -2SD and +2SD lines (simplified)
    // In production, you'd plot actual WHO curves
  }

  void _drawGrowthLines(Canvas canvas, Size size, List<GrowthRecord> sorted) {
    if (sorted.length < 2) return;

    final linePaint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < sorted.length - 1; i++) {
      final start = _getPoint(sorted[i], size);
      final end = _getPoint(sorted[i + 1], size);
      
      if (start != null && end != null) {
        canvas.drawLine(start, end, linePaint);
      }
    }
  }

  void _drawDataPoints(Canvas canvas, Size size, List<GrowthRecord> sorted) {
    for (var record in sorted) {
      final point = _getPoint(record, size);
      if (point == null) continue;

      final status = GrowthCalculator.calculateWeightStatus(
        record.weight,
        record.ageInMonths,
        gender,
      );
      
      final pointPaint = Paint()
        ..color = GrowthCalculator.getStatusColor(status)
        ..style = PaintingStyle.fill;

      // Draw main dot
      canvas.drawCircle(point, record.isBirthRecord ? 6 : 5, pointPaint);
      
      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(point, record.isBirthRecord ? 6 : 5, borderPaint);
    }
  }

  Offset? _getPoint(GrowthRecord record, Size size) {
    const double minWeight = 0;
    const double maxWeight = 20;
    const int maxAge = 24;

    final x = (record.ageInMonths / maxAge) * size.width;
    final normalizedWeight = (record.weight - minWeight) / (maxWeight - minWeight);
    final y = size.height * (1 - normalizedWeight.clamp(0, 1));
    
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}