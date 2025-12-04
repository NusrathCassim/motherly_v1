import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motherly_v1/registration.dart';


void main() {
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

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ---------------- GRADIENT BACKGROUND ----------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFBB7E7), // top
                  Color.fromARGB(255, 255, 236, 250),
                  Color.fromARGB(255, 255, 154, 223),
                  Color.fromARGB(255, 165, 0, 132), // bottom
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

          // ---------------- MAIN CONTENT ----------------
          Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const SizedBox(height: 90),

    // LOGO WITH CIRCLE
    Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 121, 166).withOpacity(0.3),
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
      "Motherly",
      style: TextStyle(
        fontFamily: "Cookie",
        fontSize: 60,
        color: const Color.fromARGB(255, 255, 238, 248).withOpacity(0.9),
      ),
    ),

    const SizedBox(height: 50),

    // GET STARTED BUTTON
    ElevatedButton(
      onPressed: () {
        // Navigate to next screen
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 232, 245),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        "GET STARTED",
        style: TextStyle(
          fontSize: 12,
          color: Color.fromARGB(255, 175, 23, 134),
        ),
      ),
    ),

    const SizedBox(height: 20),

    // SIGN UP TEXT
    GestureDetector(
      onTap: () {
        // Navigate to registration page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationScreen(), // Replace with your registration page
          ),
        );
      },
      child: RichText(
        text: const TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(color: Colors.white70, fontSize: 14),
          children: [
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
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

        ],
      ),
    );
  }
}



//
// ---------- CURVED WAVE PAINTER (3 LAYERS) ----------
//
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
        size.width * 0.5, size.height * -0.20, // deeper curve peak
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
        size.width * 0.5, size.height * -0.10, // more bent
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
        size.width * 0.5, size.height * 0.10, // more bent
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
