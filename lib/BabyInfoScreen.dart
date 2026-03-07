import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motherly_v1/models/infant_model.dart';

class BabyInfoScreen extends StatelessWidget {
  final bool isSinhala;
  final InfantModel infant;

  const BabyInfoScreen({
    super.key,
    required this.isSinhala,
    required this.infant,
  });

  // Get theme color based on gender
  Color get _themeColor {
    final gender = infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue;
    }
    return Colors.pink; // Default for girls
  }

  // Light theme color for backgrounds
  Color get _lightThemeColor {
    return _themeColor.withOpacity(0.1);
  }

  // Very light theme color for screen background
  Color get _backgroundColor {
    final gender = infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue.shade50; // Light blue for boys
    }
    return Colors.pink.shade50; // Light pink for girls
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Dynamic background color
      appBar: AppBar(
        title: Text(
          isSinhala ? 'දරුවාගේ තොරතුරු' : 'Baby Information',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _themeColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header - Minimal
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  // Avatar with gradient
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _themeColor,
                          _themeColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        infant.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Name and gender
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          infant.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _lightThemeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            infant.gender?.toLowerCase() == 'boy'
                                ? (isSinhala ? 'පිරිමි' : 'Boy')
                                : (isSinhala ? 'ගැහැණු' : 'Girl'),
                            style: TextStyle(
                              color: _themeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    icon: Icons.cake_outlined,
                    label: isSinhala ? 'උපන් දිනය' : 'Birth Date',
                    value: DateFormat('dd MMM yyyy').format(infant.dateOfBirth),
                  ),
                  _buildStatCard(
                    icon: Icons.monitor_weight_outlined,
                    label: isSinhala ? 'බර' : 'Weight',
                    value: '${infant.weight?.toStringAsFixed(1) ?? '0'} kg',
                  ),
                  _buildStatCard(
                    icon: Icons.height_outlined,
                    label: isSinhala ? 'උස' : 'Height',
                    value: '${infant.height?.toStringAsFixed(1) ?? '0'} cm',
                  ),
                  _buildStatCard(
                    icon: Icons.bloodtype_outlined,
                    label: isSinhala ? 'රුධිරය' : 'Blood',
                    value: infant.bloodType ?? (isSinhala ? '—' : '—'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Age Card - Minimal
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _lightThemeColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _themeColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _themeColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isSinhala ? 'වයස' : 'Age',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _getAgeDisplay(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _themeColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _themeColor,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _getAgeDisplay() {
    final now = DateTime.now();
    final birthDate = infant.dateOfBirth;
    
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;
    
    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month - 1, 0).day;
    }
    
    if (months < 0) {
      years--;
      months += 12;
    }
    
    if (years > 0) {
      return isSinhala ? 'වසර $years' : '$years yrs';
    } else if (months > 0) {
      return isSinhala ? 'මාස $months' : '$months mo';
    } else {
      return isSinhala ? 'දින $days' : '$days days';
    }
  }
}