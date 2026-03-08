import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motherly_v1/home_screen.dart';
import 'package:motherly_v1/registration.dart';
import 'services/firebase_notification_service.dart';

class LoginScreen extends StatefulWidget {
  final NotificationService notificationService;
  const LoginScreen({super.key, required this.notificationService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. Check if email is verified
        if (!user.emailVerified) {
          _showEmailNotVerifiedDialog();
          return;
        }

        // 3. Save FCM token
        await widget.notificationService.saveFcmToken(user.uid);

        // 4. Check due vaccines
        await widget.notificationService.checkDueVaccines(user.uid);

        // 5. Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              motherId: user.uid,
              notificationService: widget.notificationService,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.mark_email_unread, color: Colors.orange, size: 50),
            const SizedBox(height: 10),
            const Text(
              'Email Not Verified',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Please verify your email before signing in. '
          'Check your inbox for the verification link sent to ${emailController.text}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.currentUser?.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification email resent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Resend',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later';
      default:
        return 'Login failed. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // GRADIENT BACKGROUND
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
            
            // BOTTOM CURVES
            Positioned(
              bottom: 0,
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
            
            // MAIN CONTENT
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 38, 
                            fontWeight: FontWeight.bold, 
                            fontFamily: "Poppins", 
                            color: Color.fromARGB(255, 136, 20, 59),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Email Field
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFA50084),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFA50084),
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => isPasswordVisible = !isPasswordVisible);
                              },
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter your password' : null,
                        ),
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 222, 233),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Login Button
                        ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 20),
                        
                        // Sign Up Link
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationScreen(
                                  notificationService: widget.notificationService,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 222, 233),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep your BottomCurvesPainter class here
class BottomCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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