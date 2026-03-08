import 'dart:isolate';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:motherly_v1/services/firebase_notification_service.dart';

class BackgroundCheckService {
  static const String _helloAlarmTag = 'motherly.daily.vaccine.check';
  
  // Initialize the alarm manager
  static Future<void> initialize() async {
    try {
      // Request precise alarm permission for Android 12+
      await AndroidAlarmManager.initialize();
      print("✅ Android Alarm Manager initialized");
    } catch (e) {
      print("❌ Failed to initialize alarm manager: $e");
    }
  }

  // Register daily task at a specific time (e.g., 9:00 AM)
  static Future<void> registerDailyTask() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM
    
    // If the scheduled time has already passed today, schedule for tomorrow
    final scheduleDate = scheduledTime.isAfter(now) 
        ? scheduledTime 
        : scheduledTime.add(const Duration(days: 1));
    
    try {
      await AndroidAlarmManager.periodic(
        const Duration(hours: 24), // Run every 24 hours
        _helloAlarmTag.hashCode,    // Unique ID
        _alarmCallback,
        startAt: scheduleDate,      // Start at specific time
        exact: true,                 // Exact timing
        wakeup: true,                // Wake up device if needed
        rescheduleOnReboot: true,    // Keep after reboot
      );
      
      print("⏰ Registered daily vaccine check at ${scheduleDate.toIso8601String()}");
    } catch (e) {
      print("❌ Failed to register alarm: $e");
    }
  }

  // The callback function that runs in the background
  @pragma('vm:entry-point')
  static void _alarmCallback() async {
    print("🔄 Background alarm triggered at ${DateTime.now()}");
    
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Run the daily check
    await _runDailyChecks();
  }

  static Future<void> _runDailyChecks() async {
    try {
      print("🔍 Running daily vaccination checks...");
      
      // Get all mothers (users)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      final notificationService = NotificationService();
      await notificationService.initNotifications();
      
      for (var userDoc in usersSnapshot.docs) {
        final motherId = userDoc.id;
        
        // Check and schedule 3-day reminders
        await notificationService.scheduleAllUpcomingReminders(motherId);
        
        // Check for due vaccines today
        await notificationService.checkDueVaccines(motherId);
      }
      
      print("✅ Daily checks completed at ${DateTime.now()}");
    } catch (e) {
      print("❌ Error in daily checks: $e");
    }
  }

  // Run a one-time check immediately (for testing)
  static Future<void> runManualCheck() async {
    print("🔍 Manual check triggered");
    
    // Initialize Firebase if needed
    await Firebase.initializeApp();
    
    await _runDailyChecks();
  }

  // Cancel all alarms
  static Future<void> cancelAll() async {
    try {
      await AndroidAlarmManager.cancel(_helloAlarmTag.hashCode);
      print("🛑 Cancelled all background alarms");
    } catch (e) {
      print("❌ Failed to cancel alarms: $e");
    }
  }
}