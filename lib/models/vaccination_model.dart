import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationModel {
  final String id;
  final String infantId;
  final String vaccineName;
  final DateTime scheduledDate;
  final String status; // 'pending', 'completed', 'missed'


  VaccinationModel({
    required this.id,
    required this.infantId,
    required this.vaccineName,
    required this.scheduledDate,
    required this.status,

  });

  factory VaccinationModel.fromFirestore(String id, Map<String, dynamic> data) {
    return VaccinationModel(
      id: id,
      infantId: data['infantId'] ?? '',
      vaccineName: data['vaccineName'] ?? '',
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',

    );
  }

  // Days until scheduled date
  int get daysUntil {
    final now = DateTime.now();
    return scheduledDate.difference(now).inDays;
  }

  // Is upcoming (within next 7 days)
  bool get isUpcoming {
    return daysUntil >= 0 && daysUntil <= 7;
  }

  // Is overdue
  bool get isOverdue {
    return daysUntil < 0 && status == 'pending';
  }

  Map<String, dynamic> toMap() {
    return {
      'infantId': infantId,
      'vaccineName': vaccineName,
      'scheduledDate': scheduledDate,
      'status': status,
    };
  }
}