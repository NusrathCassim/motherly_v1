import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motherly_v1/models/LearnArticle.dart';
import 'package:motherly_v1/models/calender_event_modal.dart';
import 'package:motherly_v1/models/growth_record_model.dart';
import 'package:motherly_v1/models/user_model.dart';
import 'package:motherly_v1/models/infant_model.dart';
import 'package:motherly_v1/models/vaccination_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
 
 Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber ?? '',
        'address': user.address ?? '',
        'language': user.language ?? 'english',
        'profilePictureUrl': user.profilePictureUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('User created successfully in Firestore: ${user.id}');
    } catch (e) {
      print('Error creating user in Firestore: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }
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
  // Simple method to save just the scan result
Future<void> saveScanResult({
  required String infantId,
  required String result, // The prediction result
}) async {
  try {
    // Save to health_scans collection with just 3 fields
    await _db.collection('health_scans').add({
      'infantId': infantId,
      'timestamp': FieldValue.serverTimestamp(), // Auto timestamp
      'result': result,
    });
    
    // Also update the infant's last scan date
    await _db.collection('infants').doc(infantId).update({
      'lastScanDate': FieldValue.serverTimestamp(),
    });
    
    print('Scan result saved');
  } catch (e) {
    print('Error saving scan: $e');
  }
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
  
  Future<void> updateVaccinationStatus(VaccinationModel vaccination) async {
  try {
    await _db
        .collection('infant_vaccinations')
        .doc(vaccination.id)
        .update({
          'status': vaccination.status,
          // Add any other fields that need updating
        });
    print(' Vaccination status updated successfully');
  } catch (e) {
    print(' Error updating vaccination status: $e');
    throw e;
  }
}
//GET DAILY TIPS
  Future<Map<String, String>> getDailyTips() async {
    try {
      final query = await _db.collection('dailyTips').get();
      if (query.docs.isNotEmpty) {
        // Get a random tip from the collection
        final randomIndex = DateTime.now().millisecondsSinceEpoch % query.docs.length;
        final tipData = query.docs[randomIndex].data();
        // Convert to Map<String, String> using your actual field names
        return {
          'en': tipData['Etip'] as String? ?? 'No English tip available',
          'si': tipData['Stip'] as String? ?? 'සිංහල උපදෙසක් නැත',
        };
      }
      return {};
    } catch (e) {
      print('Error getting daily tips: $e');
      return {};
    }
  }

  // Add to your FirestoreService class
Future<void> updateUser(UserModel user) async {
  try {
    await _db.collection('users').doc(user.id).update({
      'name': user.name,
      'phoneNumber': user.phoneNumber,
      'address': user.address,
      'language': user.language,
      'profilePictureUrl': user.profilePictureUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('User updated successfully');
  } catch (e) {
    print('Error updating user: $e');
    throw e;
  }
}

// Method 2: Keep your existing method for other uses
Future<void> updateUserFields(String userId, Map<String, dynamic> data) async {
  try {
    // Add timestamp directly, not inside the map that might be nested
    final updateData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    await _db.collection('users').doc(userId).update(updateData);
    print('User fields updated successfully');
  } catch (e) {
    print('Error updating user fields: $e');
    throw e;
  }
}

// Add these methods to your FirestoreService class

// Get all learn articles as stream
Stream<List<LearnArticle>> getLearnArticles() {
  return _db
      .collection('Articles')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => LearnArticle.fromFirestore(doc))
        .toList();
  });
}

// Get articles by category
Stream<List<LearnArticle>> getLearnArticlesByCategory(String category) {
  return _db
      .collection('Articles')
      .where('category', isEqualTo: category)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => LearnArticle.fromFirestore(doc))
        .toList();
  });
}

// Get single article
Future<LearnArticle?> getLearnArticle(String id) async {
  try {
    final doc = await _db.collection('Articles').doc(id).get();
    if (doc.exists) {
      return LearnArticle.fromFirestore(doc);
    }
  } catch (e) {
    print('Error getting learn article: $e');
  }
  return null;
}

// Get all unique categories (one-time fetch)
Future<List<String>> getCategories() async {
  try {
    final query = await _db.collection('Articles').get();
    final categories = query.docs
        .map((doc) => doc.data()['category'] as String)
        .where((category) => category.isNotEmpty) // Remove empty categories
        .toSet()
        .toList();
    return categories;
  } catch (e) {
    print('Error getting categories: $e');
    return [];
  }
}

// Get categories as stream (real-time updates)
Stream<List<String>> getCategoriesStream() {
  return _db.collection('Articles').snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => doc.data()['category'] as String)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
  });
}
  CollectionReference get _calendarEvents =>  _db.collection('user_calender');
  // Add a calendar event
  Future<String> addCalendarEvent(CalendarEventModel event) async {
    try {
      final docRef = await _calendarEvents.add(event.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding calendar event: $e');
      throw e;
    }
  }

  // Update a calendar event
  Future<void> updateCalendarEvent(CalendarEventModel event) async {
    try {
      await _calendarEvents.doc(event.eventId).update({
        'title': event.title,
        'description': event.description,
        'eventDate': Timestamp.fromDate(event.eventDate),
        'eventType': event.eventType,
        'iconType': event.iconType,
        'color': event.color.value.toString(),
        'isRecurring': event.isRecurring,
        'recurringPattern': event.recurringPattern,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating calendar event: $e');
      throw e;
    }
  }

  // Delete a calendar event
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await _calendarEvents.doc(eventId).delete();
    } catch (e) {
      print('Error deleting calendar event: $e');
      throw e;
    }
  }

  // Get all events for an infant in a date range
  Future<List<CalendarEventModel>> getInfantEvents(
    String infantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _calendarEvents.where('infantId', isEqualTo: infantId);
      
      if (startDate != null) {
        query = query.where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('eventDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      query = query.orderBy('eventDate', descending: false);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => CalendarEventModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting infant events: $e');
      return [];
    }
  }

  // Get events for a specific month
  Future<List<CalendarEventModel>> getMonthEvents(String infantId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    return getInfantEvents(
      infantId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  // Get today's events
  Future<List<CalendarEventModel>> getTodayEvents(String infantId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return getInfantEvents(
      infantId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

}