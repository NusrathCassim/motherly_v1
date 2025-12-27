import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_notification_service.dart';
import 'home_screen.dart';

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

  bool isSinhala = false;
  bool showBabySection = false;
  bool isLoading = false;

  BabyGender? selectedGender;
  DateTime? babyDob;

  // Controllers
  final motherName = TextEditingController();
  final motherEmail = TextEditingController();
  final motherPassword = TextEditingController();
  final motherAddress = TextEditingController();

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

  // Firebase register
  Future<void> register() async {
    if (!_formKey.currentState!.validate() ||
        selectedGender == null ||
        babyDob == null) return;

    setState(() => isLoading = true);

    try {
      final motherRef =
          await FirebaseFirestore.instance.collection('users').add({
        'name': motherName.text.trim(),
        'email': motherEmail.text.trim(),
        'password': motherPassword.text.trim(),
        'address': motherAddress.text.trim(),
        'fcmToken': null,
      });

      await widget.notificationService.saveFcmToken(motherRef.id);

      final infantRef =
          await FirebaseFirestore.instance.collection('infants').add({
        'mother_id': motherRef.id,
        'name': babyName.text.trim(),
        'dob': Timestamp.fromDate(babyDob!),
        'gender': selectedGender == BabyGender.boy ? 'boy' : 'girl',
        'weight': double.parse(babyWeight.text),
        'height': double.parse(babyHeight.text),
        'bloodType': babyBlood.text.trim(),
      });

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
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            motherId: motherRef.id,
            notificationService: widget.notificationService,
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(22, 15, 24, 20), // top padding for heart
          child: Column(
            children: [

              //  HEART TOGGLE (CENTERED)
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

              // ---------------- MOTHER DETAILS ----------------
              _card(
                title: isSinhala ? 'මවගේ තොරතුරු' : 'Mother Details',
                children: [
                  _input(motherName, isSinhala ? 'මවගේ නම' : 'Mother Name'),
                  _input(motherEmail, isSinhala ? 'ඊමේල්' : 'Email'),
                  _input(motherPassword, isSinhala ? 'මුරපදය' : 'Password', obscure: true),
                  _input(motherAddress, isSinhala ? 'ලිපිනය' : 'Address'),
                ],
              ),

              const SizedBox(height: 24),

              // ---------------- BABY GENDER ----------------
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

              // ---------------- BABY DETAILS (IF SELECTED) ----------------
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
          BoxShadow(
              blurRadius: 20, color: Colors.black12, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(
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
        validator: (v) => v!.isEmpty ? 'Required' : null,
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
    return Row(
      children: [
        Expanded(
          child: Text(
            babyDob == null
                ? (isSinhala ? 'උපන් දිනය' : 'Date of Birth')
                : babyDob!.toLocal().toString().split(' ')[0],
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 30)),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => babyDob = picked);
          },
          child: const Text('Pick'),
        )
      ],
    );
  }
}
