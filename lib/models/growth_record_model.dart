import 'package:cloud_firestore/cloud_firestore.dart';

class GrowthRecord {
  final String id;
  final String infantId;
  final DateTime date;
  final double weight;
  final double? height;
  final int ageInMonths;
  final bool isBirthRecord;

  GrowthRecord({
    required this.id,
    required this.infantId,
    required this.date,
    required this.weight,
    this.height,
    required this.ageInMonths,
    this.isBirthRecord = false,
  });

  factory GrowthRecord.fromJson(String id, Map<String, dynamic> json) {
    return GrowthRecord(
      id: id,
      infantId: json['infantId'] ?? '',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: (json['weight'] ?? 0).toDouble(),
      height: json['height']?.toDouble(),
      ageInMonths: json['ageInMonths'] ?? 0,
      isBirthRecord: json['isBirthRecord'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'infantId': infantId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'ageInMonths': ageInMonths,
      'isBirthRecord': isBirthRecord,
    };
  }
}