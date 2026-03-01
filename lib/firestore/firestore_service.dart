import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motherly_v1/models/growth_record_model.dart';
import 'package:motherly_v1/models/user_model.dart';
import 'package:motherly_v1/models/infant_model.dart';
import 'package:motherly_v1/models/vaccination_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User methods
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.id, doc.data()!);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  // Infant methods
  Future<InfantModel?> getInfantByMotherId(String motherId) async {
    try {
      final query = await _db
          .collection('infants')
          .where('mother_id', isEqualTo: motherId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return InfantModel.fromFirestore(doc.id, doc.data());
      }
    } catch (e) {
      print('Error getting infant: $e');
    }
    return null;
  }
    Future<InfantModel?> getInfant(String infantId) async {
    try {
      final doc = await _db.collection('infants').doc(infantId).get();
      if (doc.exists) {
        return InfantModel.fromFirestore(doc.id, doc.data()!);
      }
    } catch (e) {
      print('Error getting infant by ID: $e');
    }
    return null;
  }

  // Vaccination methods
  Future<List<VaccinationModel>> getVaccinations(String infantId) async {
    try {
      final query = await _db
          .collection('infant_vaccinations')
          .where('infantId', isEqualTo: infantId)
          .orderBy('scheduledDate')
          .get();
      
      return query.docs.map((doc) => 
        VaccinationModel.fromFirestore(doc.id, doc.data())
      ).toList();
    } catch (e) {
      print('Error getting vaccinations: $e');
      return [];
    }
  }

  // Get next upcoming vaccination
  Future<VaccinationModel?> getNextVaccination(String infantId) async {
    try {
      final now = DateTime.now();
      final query = await _db
          .collection('infant_vaccinations')
          .where('infantId', isEqualTo: infantId)
          .where('status', isEqualTo: 'pending')
          .where('scheduledDate', isGreaterThanOrEqualTo: now)
          .orderBy('scheduledDate')
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return VaccinationModel.fromFirestore(query.docs.first.id, query.docs.first.data());
      }
    } catch (e) {
      print('Error getting next vaccination: $e');
    }
    return null;
  }

  // Get pending vaccinations count
  Future<int> getPendingVaccinationsCount(String infantId) async {
    try {
      final query = await _db
          .collection('infant_vaccinations')
          .where('infantId', isEqualTo: infantId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return query.docs.length;
    } catch (e) {
      print('Error getting pending count: $e');
      return 0;
    }
  }

  // Get last scan date (you'll need to create this collection)
  Future<DateTime?> getLastScanDate(String infantId) async {
    try {
      final query = await _db
          .collection('health_scans')
          .where('infantId', isEqualTo: infantId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return (query.docs.first.data()['timestamp'] as Timestamp?)?.toDate();
      }
    } catch (e) {
      print('Error getting last scan: $e');
    }
    return null;
  }
  // Add to your existing FirestoreService class

Future<List<GrowthRecord>> getGrowthRecords(String infantId) async {
  try {
    final query = await _db
        .collection('growth_records')
        .where('infantId', isEqualTo: infantId)
        .orderBy('date')
        .get();
    
    return query.docs.map((doc) => 
      GrowthRecord.fromJson(doc.id, doc.data())
    ).toList();
  } catch (e) {
    print('Error getting growth records: $e');
    return [];
  }
}

Future<void> addGrowthRecord(GrowthRecord record) async {
  try {
    await _db
        .collection('growth_records')
        .add(record.toJson());
  } catch (e) {
    print('Error adding growth record: $e');
  }
}

Future<void> deleteGrowthRecord(String recordId) async {
  try {
    await _db
        .collection('growth_records')
        .doc(recordId)
        .delete();
  } catch (e) {
    print('Error deleting growth record: $e');
  }
}

}