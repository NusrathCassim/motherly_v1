import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications
  Future<void> initNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Request permissions for Android 13+
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.requestNotificationsPermission();
  }

  // Show immediate local notification
  Future<void> showNotification({
    required String title, 
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vaccine_channel',
      'Vaccination Reminders',
      channelDescription: 'Reminders for baby vaccines',
      importance: Importance.max,
      priority: Priority.high,
      ledColor: Color(0xFFFF4081),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableLights: true,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
  
  // Schedule a notification for 3 days before vaccine
  Future<void> scheduleVaccineReminder({
    required String vaccineId,
    required String vaccineName,
    required String infantName,
    required DateTime scheduledDate,
    required bool isSinhala,
  }) async {
    // Calculate 3 days before due date
    final reminderDate = scheduledDate.subtract(const Duration(days: 3));
    
    // Only schedule if reminder date is in the future
    if (reminderDate.isAfter(DateTime.now())) {
      final String title = isSinhala 
          ? 'එන්නත් මතක් කිරීම' 
          : 'Vaccination Reminder';
      
      final String body = isSinhala
          ? '$infantName ගේ $vaccineName එන්නත දින 3 කින්'
          : '$vaccineName for $infantName is due in 3 days';
      
      // Use vaccineId as a unique notification ID
      final int notificationId = vaccineId.hashCode;
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'vaccine_channel_3day',
        '3-Day Vaccine Reminders',
        channelDescription: 'Reminders 3 days before vaccine due date',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const NotificationDetails platformDetails = 
          NotificationDetails(android: androidDetails);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(reminderDate, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      
      print('✅ Scheduled 3-day reminder for $vaccineName on $reminderDate');
    }
  }
  
  // Cancel a specific reminder
  Future<void> cancelReminder(String vaccineId) async {
    final notificationId = vaccineId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    print('Cancelled reminder for vaccine ID: $vaccineId');
  }
  
  // Check all vaccines and schedule 3-day reminders
  Future<void> scheduleAllUpcomingReminders(String motherId) async {
    final today = DateTime.now();
    
    // Get all infants for this mother
    final infantsSnapshot = await FirebaseFirestore.instance
        .collection('infants')
        .where('mother_id', isEqualTo: motherId)
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
        final vaccineId = vacDoc.id;
        
        // Check if already notified
        final notifiedDays = List<int>.from(vacDoc.data().containsKey('notifiedDays') 
            ? vacDoc['notifiedDays'] 
            : []);
        
        // Calculate days until vaccine
        final daysUntil = scheduledDate.difference(today).inDays;
        
        // Schedule 3-day reminder if exactly 3 days away and not already notified
        if (daysUntil == 3 && !notifiedDays.contains(3)) {
          // Get user's language preference
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(motherId)
              .get();
          final isSinhala = userDoc.data()?['language'] == 'sinhala';
          
          await scheduleVaccineReminder(
            vaccineId: vaccineId,
            vaccineName: vaccineName,
            infantName: infantName,
            scheduledDate: scheduledDate,
            isSinhala: isSinhala,
          );
          
          // Mark as notified
          await vacDoc.reference.update({
            'notifiedDays': FieldValue.arrayUnion([3])
          });
        }
      }
    }
  }

  // Daily check for due vaccines (immediate notifications)
  Future<void> checkDueVaccines(String motherId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get all infants for this mother
    final infantsSnapshot = await FirebaseFirestore.instance
        .collection('infants')
        .where('mother_id', isEqualTo: motherId)
        .get();

    for (var infantDoc in infantsSnapshot.docs) {
      final infantId = infantDoc.id;
      final infantName = infantDoc['name'];

      // Get pending vaccines due today
      final vaccineSnapshot = await FirebaseFirestore.instance
          .collection('infant_vaccinations')
          .where('infantId', isEqualTo: infantId)
          .where('status', isEqualTo: 'pending')
          .where('scheduledDate', isGreaterThanOrEqualTo: todayStart)
          .where('scheduledDate', isLessThan: todayEnd)
          .get();

      for (var vacDoc in vaccineSnapshot.docs) {
        final vaccineName = vacDoc['vaccineName'];
        final vaccineId = vacDoc.id;
        
        // Get user's language preference
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(motherId)
            .get();
        final isSinhala = userDoc.data()?['language'] == 'sinhala';
        
        final title = isSinhala 
            ? 'අද එන්නත් දිනය' 
            : 'Vaccine Due Today';
        final body = isSinhala
            ? '$infantName ගේ $vaccineName එන්නත අදයි'
            : '$vaccineName for $infantName is due today';
        
        await showNotification(
          id: vaccineId.hashCode + 1000, // Different ID to avoid conflict
          title: title,
          body: body,
        );
      }
    }
  }

  // Save FCM token for push notifications
  Future<void> saveFcmToken(String userId) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
    }
  }

  // Setup Firebase Cloud Messaging listeners
  Future<void> setupFCM() async {
    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    
    // Listen to messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
        );
      }
    });
    
    // When app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Navigate to specific screen based on message data
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Check and schedule all reminders for a mother (called from background)
  Future<void> runDailyCheck(String motherId) async {
    await scheduleAllUpcomingReminders(motherId);
    await checkDueVaccines(motherId);
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // Handle background message
}