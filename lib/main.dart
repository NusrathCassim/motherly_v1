import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motherly_v1/services/background_check_service.dart';
import 'package:motherly_v1/services/firebase_notification_service.dart';
import 'package:motherly_v1/services/firebase_options.dart';
import 'package:motherly_v1/login_screen.dart';
import 'package:motherly_v1/registration.dart';
import 'package:easy_sinhala_text/easy_sinhala_text.dart';

late NotificationService notificationService;
Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  notificationService = NotificationService();
  await notificationService.initNotifications();
  
  // Set up FCM
  await notificationService.setupFCM();
  
  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  
  // Initialize background service with alarm manager
  await BackgroundCheckService.initialize();
  
  // Register daily task (9:00 AM)
  await BackgroundCheckService.registerDailyTask();
  
  runApp(const MyApp());


}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isSinhala = false;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ---------------- GRADIENT BACKGROUND ----------------
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFBB7E7),
                    Color.fromARGB(255, 255, 236, 250),
                    Color.fromARGB(255, 255, 154, 223),
                    Color.fromARGB(255, 165, 0, 132),
                  ],
                ),
              ),
            ),

            // ---------------- BOTTOM CURVES ----------------
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width,
                  height * 0.4,
                ),
                painter: BottomCurvesPainter(),
              ),
            ),

            // ---------------- TOGGLE BUTTON (HEART) ----------------
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: isSinhala ? Colors.pink : Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    isSinhala = !isSinhala;
                  });
                },
              ),
            ),

            // ---------------- MAIN CONTENT ----------------
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 90),

                  // LOGO WITH SHADOW
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 121, 166)
                              .withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/image.png",
                      width: 120,
                      height: 120,
                    ),
                  ),

                  const SizedBox(height: 150),

                  // TITLE
                  Text(
                    isSinhala ? "මදර්ලි" : "Motherly",
                    style: TextStyle(
                      fontFamily: "Cookie",
                      fontSize: 60,
                      color: const Color.fromARGB(255, 255, 238, 248)
                          .withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // GET STARTED BUTTON
                  ElevatedButton(
                    onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              notificationService: notificationService,
                            ),
                          ),
                        );
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 255, 232, 245),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isSinhala ? "ආරම්භ කරන්න" : "GET STARTED",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 175, 23, 134),
                      ),
                    ),
                    
                  ),

                  const SizedBox(height: 20),

                  // SIGN UP TEXT
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(
                          notificationService: notificationService,
                        ),
                      ),
                    );

                    },
                    child: RichText(
                      text: TextSpan(
                        text: isSinhala
                            ? "ගිණුමක් නැද්ද? "
                            : "Don't have an account? ",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                        children: [
                          TextSpan(
                            text: isSinhala
                                ? "ලියාපදිංචි වන්න"
                                : "Sign Up",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 182, 241),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// CUSTOM CURVES PAINTER
// ---------------------------------------------------

class BottomCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ===== 1st layer (lightest) =====
    final paint1 = Paint()
      ..color = const Color.fromARGB(255, 255, 122, 217).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.10)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * -0.20,
        size.width, size.height * 0.10,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);

    // ===== 2nd layer =====
    final paint2 = Paint()
      ..color = const Color.fromARGB(255, 255, 82, 195).withOpacity(0.30)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * -0.10,
        size.width, size.height * 0.25,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);

    // ===== 3rd layer =====
    final paint3 = Paint()
      ..color = const Color.fromARGB(255, 245, 0, 143).withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final path3 = Path()
      ..moveTo(0, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.10,
        size.width, size.height * 0.40,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
  
  // Initialize notification service if needed
  final notificationService = NotificationService();
  await notificationService.initNotifications();
  
  // Show the notification
  if (message.notification != null) {
    await notificationService.showNotification(
      title: message.notification!.title ?? 'Vaccination Reminder',
      body: message.notification!.body ?? '',
    );
  }
  
  // Handle data messages
  if (message.data.isNotEmpty) {
    print('Message data: ${message.data}');
    // You can handle specific actions based on data
  }
}