import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications
  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show local notification
  Future<void> showNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vaccine_channel',
      'Vaccination Reminders',
      channelDescription: 'Reminders for baby vaccines',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }
  Future<void> saveFcmToken(String userId) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
    }
  }

  // Check for due vaccines for a mother and show notifications
  Future<void> checkDueVaccines(String motherId) async {
    final today = DateTime.now();

    // Get all infants for this mother
    final infantsSnapshot = await FirebaseFirestore.instance
        .collection('infants')
        .where('mother_Id', isEqualTo: motherId)
        .get();

    for (var infantDoc in infantsSnapshot.docs) {
      final infantId = infantDoc.id;
      final infantName = infantDoc['name'];

      // Get pending vaccines for this infant
      final vaccineSnapshot = await FirebaseFirestore.instance
          .collection('infant_vaccinations')
          .where('infantId', isEqualTo: infantId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var vacDoc in vaccineSnapshot.docs) {
        final scheduledDate = (vacDoc['scheduledDate'] as Timestamp).toDate();
        final vaccineName = vacDoc['vaccineName'];

        // If scheduled date is today or earlier
        if (!scheduledDate.isAfter(today)) {
          await showNotification(
            title: 'Vaccine Due Today',
            body: 'Your baby $infantName is due for $vaccineName.',
          );
        }
      }
    }
  }
}
