// models/calendar_event_model.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  final String eventId;
  final String infantId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String eventType; 
  final String iconType;
  final Color color; // Store as hex string
  final bool isRecurring;
  final String? recurringPattern; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CalendarEventModel({
    required this.eventId,
    required this.infantId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventType,
    required this.iconType,
    required this.color,
    this.isRecurring = false,
    this.recurringPattern,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'infantId': infantId,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventType': eventType,
      'iconType': iconType,
      'color': color.value.toString(), // Store as hex string
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore
  factory CalendarEventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CalendarEventModel(
      eventId: doc.id,
      infantId: data['infantId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      eventType: data['eventType'] ?? 'custom',
      iconType: data['iconType'] ?? '📝',
      color: Color(int.parse(data['color'] ?? '0xFF9C27B0')),
      isRecurring: data['isRecurring'] ?? false,
      recurringPattern: data['recurringPattern'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}