import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_notification_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

enum BabyGender { boy, girl }

class RegistrationScreen extends StatefulWidget {
  final NotificationService notificationService;
  const RegistrationScreen({super.key, required this.notificationService});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSinhala = false;
  bool showBabySection = false;
  bool isLoading = false;

  BabyGender? selectedGender;
  DateTime? babyDob;

  // Controllers
  final motherName = TextEditingController();
  final motherEmail = TextEditingController();
  final motherPassword = TextEditingController();
  final motherConfirmPassword = TextEditingController();
  final motherAddress = TextEditingController();
  final language = TextEditingController();

  final babyName = TextEditingController();
  final babyWeight = TextEditingController();
  final babyHeight = TextEditingController();
  final babyBlood = TextEditingController();

  // Theme
  LinearGradient get gradient {
    if (selectedGender == BabyGender.girl) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 249, 136, 215),
          Color(0xFFFFECFA),
          Color.fromARGB(255, 236, 36, 196),
        ],
      );
    }
    if (selectedGender == BabyGender.boy) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFB3E5FC),
          Color(0xFFE1F5FE),
          Color(0xFF0277BD),
        ],
      );
    }
    return const LinearGradient(
      colors: [Color.fromARGB(155, 255, 239, 251), Color.fromARGB(153, 249, 251, 255)],
    );
  }

  Color get accent =>
      selectedGender == BabyGender.boy ? const Color.fromARGB(255, 145, 205, 255) : const Color.fromARGB(255, 255, 183, 207);

  // Gender select
  void selectGender(BabyGender gender) {
    setState(() {
      selectedGender = gender;
      showBabySection = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // Firebase Auth Registration
  Future<void> register() async {
    if (!_formKey.currentState!.validate() ||
        selectedGender == null ||
        babyDob == null) return;

    setState(() => isLoading = true);

    try {
      // 1. Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: motherEmail.text.trim(),
        password: motherPassword.text,
      );

      User? user = userCredential.user;
      
      if (user != null) {
        // 2. Send email verification
        await user.sendEmailVerification();

        // 3. Save mother data to Firestore (without password)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': motherName.text.trim(),
          'email': motherEmail.text.trim(),
          'address': motherAddress.text.trim(),
          'fcmToken': null,
          'language': isSinhala ? 'sinhala' : 'english',
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
          'phoneNumber':'',
          'updatedAt':''  
        });

        // 4. Save FCM token
        await widget.notificationService.saveFcmToken(user.uid);

        // 5. Save infant data
        final infantRef = await FirebaseFirestore.instance.collection('infants').add({
          'mother_id': user.uid,
          'name': babyName.text.trim(),
          'dob': Timestamp.fromDate(babyDob!),
          'gender': selectedGender == BabyGender.boy ? 'boy' : 'girl',
          'weight': double.parse(babyWeight.text),
          'height': double.parse(babyHeight.text),
          'bloodType': babyBlood.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 6. Create vaccinations
        final vaccines = await FirebaseFirestore.instance
            .collection('master_vaccines')
            .get();

        for (var doc in vaccines.docs) {
          final months = doc['recommendedAgeInMonths'] ?? 0;
          final date = babyDob!.add(Duration(days: months * 30));

          await FirebaseFirestore.instance
              .collection('infant_vaccinations')
              .add({
            'infantId': infantRef.id,
            'vaccineId': doc.id,
            'vaccineName': doc['vaccineName'],
            'scheduledDate': Timestamp.fromDate(date),
            'status': 'pending',
            'notifiedDays': [],
          });
        }

        // 7. Show verification dialog
        _showVerificationDialog();
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

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.mark_email_read, color: accent, size: 60),
            const SizedBox(height: 10),
            Text(
              isSinhala ? 'ඊමේල් තහවුරු කරන්න' : 'Verify Your Email',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          isSinhala
              ? 'අපි ${motherEmail.text} වෙත තහවුරු කිරීමේ සබැඳියක් යවා ඇත. කරුණාකර ඔබගේ ඊමේල් පරීක්ෂා කර ගිණුම සක්‍රිය කරන්න.'
              : 'We have sent a verification link to ${motherEmail.text}. Please check your email and verify your account.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    notificationService: widget.notificationService,
                  ),
                ),
              );
            },
            child: Text(
              isSinhala ? 'පිවිසුම් තිරයට' : 'Go to Login',
              style: TextStyle(color: accent),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.currentUser?.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSinhala ? 'තහවුරු කිරීමේ ඊමේල් එක නැවත යවන ලදී' : 'Verification email resent',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              isSinhala ? 'නැවත යවන්න' : 'Resend',
              style: TextStyle(color: accent),
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return isSinhala ? 'මෙම ඊමේල් ලිපිනය දැනටමත් භාවිතා වේ' : 'Email already in use';
      case 'invalid-email':
        return isSinhala ? 'වලංගු නොවන ඊමේල් ලිපිනයක්' : 'Invalid email address';
      case 'weak-password':
        return isSinhala ? 'මුරපදය දුර්වලයි. අවම වශයෙන් අකුරු 6ක් ඇතුළත් කරන්න' : 'Password is too weak';
      default:
        return isSinhala ? 'ලියාපදිංචිය අසාර්ථකයි' : 'Registration failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(22, 15, 24, 20),
              child: Column(
                children: [
                  // HEART TOGGLE
                  Center(
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: isSinhala ? Colors.pink : Colors.white,
                        size: 36,
                      ),
                      onPressed: () => setState(() => isSinhala = !isSinhala),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // MOTHER DETAILS
                  _card(
                    title: isSinhala ? 'මවගේ තොරතුරු' : 'Mother Details',
                    children: [
                      _languageSelector(),
                      _input(motherName, isSinhala ? 'මවගේ නම' : 'Mother Name'),
                      _input(motherEmail, isSinhala ? 'ඊමේල්' : 'Email'),
                      _input(motherPassword, isSinhala ? 'මුරපදය' : 'Password', obscure: true),
                      _input(motherConfirmPassword, isSinhala ? 'මුරපදය තහවුරු කරන්න' : 'Confirm Password', obscure: true),
                      _input(motherAddress, isSinhala ? 'ලිපිනය' : 'Address'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // BABY GENDER
                  _card(
                    title: isSinhala ? 'දරුවාගේ ලිංගය' : 'Select Baby Gender',
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _genderCard(Icons.boy, 'Boy', Colors.blue, BabyGender.boy),
                          _genderCard(Icons.girl, 'Girl', const Color.fromARGB(255, 245, 96, 146), BabyGender.girl),
                        ],
                      ),
                    ],
                  ),

                  // BABY DETAILS
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: showBabySection
                        ? Column(
                            children: [
                              const SizedBox(height: 24),
                              _card(
                                title: isSinhala ? 'දරුවාගේ තොරතුරු' : 'Baby Information',
                                children: [
                                  _input(babyName, isSinhala ? 'දරුවාගේ නම' : 'Baby Name'),
                                  _datePicker(),
                                  _input(babyWeight, isSinhala ? 'බර (kg)' : 'Weight (kg)', number: true),
                                  _input(babyHeight, isSinhala ? 'උස (cm)' : 'Height (cm)', number: true),
                                  _input(babyBlood, isSinhala ? 'රුධිර වර්ගය' : 'Blood Type'),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accent,
                                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      child: isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Text(isSinhala ? 'ලියාපදිංචි කරන්න' : 'Create Account'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI helpers

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(blurRadius: 20, color: Colors.black12, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, 
                  fontFamily: "Poppins",
                  color: Color.fromARGB(255, 70, 70, 70),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {bool obscure = false, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color.fromARGB(92, 234, 234, 234),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return isSinhala ? 'අවශ්‍යයි' : 'Required';
          }
          if (c == motherPassword && value.length < 6) {
            return isSinhala ? 'අවම වශයෙන් අකුරු 6ක්' : 'Minimum 6 characters';
          }
          if (c == motherConfirmPassword && value != motherPassword.text) {
            return isSinhala ? 'මුරපද ගැලපෙන්නේ නැත' : 'Passwords do not match';
          }
          if (c == motherEmail && !value.contains('@')) {
            return isSinhala ? 'වලංගු ඊමේල් එකක් නොවේ' : 'Invalid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _genderCard(
      IconData icon, String label, Color color, BabyGender gender) {
    final selected = selectedGender == gender;
    return GestureDetector(
      onTap: () => selectGender(gender),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color.fromARGB(255, 246, 246, 246),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 4),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(92, 234, 234, 234),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              babyDob == null
                  ? (isSinhala ? 'උපන් දිනය' : 'Date of Birth')
                  : '${babyDob!.day}/${babyDob!.month}/${babyDob!.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 30)),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: accent,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => babyDob = picked);
            },
            child: Text(
              isSinhala ? 'තෝරන්න' : 'Pick',
              style: TextStyle(color: accent),
            ),
          )
        ],
      ),
    );
  }

  Widget _languageSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(92, 234, 234, 234),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isSinhala = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSinhala 
                      ? Colors.pink.withOpacity(0.2) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🇱🇰', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'සිංහල',
                      style: TextStyle(
                        fontWeight: isSinhala ? FontWeight.bold : FontWeight.normal,
                        color: isSinhala ? Colors.pink : Colors.grey.shade700,
                      ),
                    ),
                    if (isSinhala) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle, color: Colors.pink, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          Container(height: 30, width: 1, color: Colors.grey.shade400),
          
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isSinhala = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !isSinhala 
                      ? Colors.blue.withOpacity(0.2) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        fontWeight: !isSinhala ? FontWeight.bold : FontWeight.normal,
                        color: !isSinhala ? Colors.blue : Colors.grey.shade700,
                      ),
                    ),
                    if (!isSinhala) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle, color: Colors.blue, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    motherName.dispose();
    motherEmail.dispose();
    motherPassword.dispose();
    motherConfirmPassword.dispose();
    motherAddress.dispose();
    babyName.dispose();
    babyWeight.dispose();
    babyHeight.dispose();
    babyBlood.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}