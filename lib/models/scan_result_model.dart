import 'package:flutter/material.dart';
class ScanResult {
  final String prediction;
  final String predictionSinhala;
  final double confidence;
  final bool requiresAttention;
  final List<String> recommendations;
  final DateTime timestamp;
  final bool? demoMode;
  final String? note;

  ScanResult({
    required this.prediction,
    required this.predictionSinhala,
    required this.confidence,
    required this.requiresAttention,
    required this.recommendations,
    required this.timestamp,
    this.demoMode,
    this.note,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      prediction: json['prediction'] ?? 'unknown',
      predictionSinhala: json['prediction_sinhala'] ?? json['prediction'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      requiresAttention: json['requires_attention'] ?? false,
      recommendations: List<String>.from(json['recommendations'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      demoMode: json['demo_mode'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'prediction_sinhala': predictionSinhala,
      'confidence': confidence,
      'requires_attention': requiresAttention,
      'recommendations': recommendations,
      'timestamp': timestamp.toIso8601String(),
      'demo_mode': demoMode,
      'note': note,
    };
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Sinhala version
  String get formattedTimestampSinhala {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'දැන්';
    } else if (difference.inHours < 1) {
      return 'විනාඩි ${difference.inMinutes} කට පෙර';
    } else if (difference.inDays < 1) {
      return 'පැය ${difference.inHours} කට පෙර';
    } else {
      return '${timestamp.year}-${timestamp.month}-${timestamp.day}';
    }
  }

  // Get color based on condition
  Color get conditionColor {
    if (prediction.toLowerCase() == 'normal_healthy') {
      return Colors.green;
    } else if (requiresAttention) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
}

// Add this import at the top of the file
