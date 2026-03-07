import 'package:cloud_firestore/cloud_firestore.dart';

class InfantModel {
  final String infantId;
  final String motherId;
  final String name;
  final DateTime dateOfBirth;
  final String gender;        // Made required since it's always present
  final double weight;
  final double height;
  final String bloodType;

  InfantModel({
    required this.infantId,
    required this.motherId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,      // Made required
    required this.weight,      // Made required
    required this.height,      // Made required
    required this.bloodType,   // Made required
  });

  factory InfantModel.fromFirestore(String infantId, Map<String, dynamic> data) {
    return InfantModel(
      infantId: infantId,
      motherId: data['mother_id'] ?? '',
      name: data['name'] ?? '',
      dateOfBirth: (data['dob'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'] ?? '',
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      height: (data['height'] as num?)?.toDouble() ?? 0.0,
      bloodType: data['bloodType'] ?? '',
    );
  }

  // Calculate age in months
  int get ageInMonths {
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth);
    return (difference.inDays / 30).floor();
  }

  // Calculate age in days (for newborns)
  int get ageInDays {
    final now = DateTime.now();
    return now.difference(dateOfBirth).inDays;
  }

  String get ageDisplay {
    if (ageInDays < 30) {
      return ageInDays == 1 ? 'දින 1' : 'දින $ageInDays';
    } else {
      return 'මාස $ageInMonths';
    }
  }

  // English version for age display
  String get ageDisplayEn {
    if (ageInDays < 30) {
      return ageInDays == 1 ? '$ageInDays day' : '$ageInDays days';
    } else {
      return ageInMonths == 1 ? '$ageInMonths month' : '$ageInMonths months';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'mother_id': motherId,
      'name': name,
      'dob': dateOfBirth,
      'gender': gender,
      'weight': weight,
      'height': height,
      'bloodType': bloodType,
    };
  }
}