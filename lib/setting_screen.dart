import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motherly_v1/main.dart';
import 'package:motherly_v1/models/infant_model.dart';
import 'package:motherly_v1/models/user_model.dart';
import 'package:motherly_v1/services/firebase_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isSinhala;
  final InfantModel infant;
  final UserModel user;
  final NotificationService notificationService;
  
  const SettingsScreen({
    super.key,
    required this.isSinhala,
    required this.user,
    required this.infant,
    required this.notificationService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _dailyTipsEnabled = true;
  bool _reminder3DaysEnabled = true;
  bool _reminder7DaysEnabled = false;

  // Get theme color based on baby's gender
  Color get _themeColor {
    final gender = widget.infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue;
    }
    return Colors.pink;
  }

  // Light theme color
  Color get _lightThemeColor {
    return _themeColor.withOpacity(0.1);
  }

  // Background color
  Color get _backgroundColor {
    final gender = widget.infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue.shade50;
    }
    return Colors.pink.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isSinhala ? 'සැකසුම්' : 'Settings',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _themeColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Summary Card
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  
                  // Account Settings Section
                  _buildSectionHeader(
                    icon: Icons.account_circle,
                    title: widget.isSinhala ? 'ගිණුම් සැකසුම්' : 'Account Settings',
                  ),
                  const SizedBox(height: 8),
                  
                  // Language Setting
                  _buildSettingsCard([
                    _buildLanguageSetting(),
                  ]),
                 
                  const SizedBox(height: 16),
                  
                  // App Settings Section
                  _buildSectionHeader(
                    icon: Icons.settings,
                    title: widget.isSinhala ? 'යෙදුම් සැකසුම්' : 'App Settings',
                  ),
                  const SizedBox(height: 8),
                  
                  _buildSettingsCard([
                    _buildAppSettingTile(
                      icon: Icons.storage,
                      iconColor: Colors.teal,
                      title: widget.isSinhala ? 'දත්ත හිස් කරන්න' : 'Clear Cache',
                      subtitle: widget.isSinhala 
                          ? 'තාවකාලික දත්ත මකන්න'
                          : 'Clear temporary data',
                      onTap: () => _showClearCacheDialog(),
                    ),
                    _buildDivider(),
                    _buildAppSettingTile(
                      icon: Icons.info,
                      iconColor: Colors.grey,
                      title: widget.isSinhala ? 'යෙදුම් තොරතුරු' : 'App Info',
                      subtitle: 'Version 1.0.0',
                      onTap: () => _showAppInfoDialog(),
                    ),
                    _buildDivider(),
                    _buildAppSettingTile(
                      icon: Icons.privacy_tip,
                      iconColor: Colors.indigo,
                      title: widget.isSinhala ? 'රහස්‍යතා ප්‍රතිපත්තිය' : 'Privacy Policy',
                      subtitle: widget.isSinhala 
                          ? 'අපගේ රහස්‍යතා ප්‍රතිපත්තිය කියවන්න'
                          : 'Read our privacy policy',
                      onTap: () => _showPrivacyPolicy(),
                    ),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Danger Zone
                  _buildSectionHeader(
                    icon: Icons.warning,
                    iconColor: Colors.red,
                    title: widget.isSinhala ? 'අවදානම් කලාපය' : 'Danger Zone',
                  ),
                  const SizedBox(height: 8),
                  
                  _buildSettingsCard([
                    _buildDangerTile(
                      icon: Icons.logout,
                      title: widget.isSinhala ? 'ඉවත් වන්න' : 'Logout',
                      subtitle: widget.isSinhala 
                          ? 'ඔබගේ ගිණුමෙන් ඉවත් වන්න'
                          : 'Sign out from your account',
                      color: Colors.orange,
                      onTap: _showLogoutConfirmation,
                    ),
                    _buildDivider(),
                    _buildDangerTile(
                      icon: Icons.delete_forever,
                      title: widget.isSinhala ? 'ගිණුම අක්‍රිය කරන්න' : 'Deactivate Account',
                      subtitle: widget.isSinhala 
                          ? 'ඔබගේ ගිණුම සහ සියලුම දත්ත ස්ථිරවම මකන්න'
                          : 'Permanently delete your account and all data',
                      color: Colors.red,
                      onTap: _showDeactivateConfirmation,
                    ),
                  ]),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // Profile Card
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_themeColor, _themeColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _themeColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _themeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.isSinhala ? 'සාමාජික' : 'Member',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor ?? _themeColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Settings Card Container
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Language Setting Tile
  Widget _buildLanguageSetting() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.language, color: Colors.blue),
      ),
      title: Text(
        widget.isSinhala ? 'භාෂාව' : 'Language',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(widget.isSinhala ? 'සිංහල' : 'English'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _lightThemeColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isSinhala ? 'සිංහල' : 'English',
              style: TextStyle(
                color: _themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: _themeColor,
              size: 18,
            ),
          ],
        ),
      ),
      onTap: () {
        // Toggle language
        _updateLanguage(!widget.isSinhala);
      },
    );
  }

  // Switch Tile for Notifications
  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    bool enabled = true,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            )
          : null,
      value: value,
      activeColor: _themeColor,
      onChanged: enabled ? onChanged : null,
    );
  }

  // App Setting Tile
  Widget _buildAppSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
      onTap: onTap,
    );
  }

  // Danger Zone Tile
  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: color, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }

  // ==================== DIALOGS AND ACTIONS ====================

  // Language Update
  Future<void> _updateLanguage(bool toSinhala) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'language': toSinhala ? 'sinhala' : 'english',
            });
        
        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                toSinhala 
                    ? 'භාෂාව සිංහලට වෙනස් කරන ලදී. කරුණාකර යෙදුම නැවත ආරම්භ කරන්න.'
                    : 'Language changed to English. Please restart the app.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: toSinhala ? 'හරි' : 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Clear Cache Dialog
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.storage, color: Colors.teal),
            const SizedBox(width: 8),
            Text(widget.isSinhala ? 'දත්ත හිස් කරන්න' : 'Clear Cache'),
          ],
        ),
        content: Text(
          widget.isSinhala
              ? 'තාවකාලික දත්ත හිස් කිරීමට අවශ්‍යද? මෙය ඔබගේ සුරකින ලද දත්ත වලට බලපාන්නේ නැත.'
              : 'Clear temporary data? This will not affect your saved data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'එපා' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.isSinhala 
                        ? 'දත්ත හිස් කරන ලදී' 
                        : 'Cache cleared',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isSinhala ? 'හිස් කරන්න' : 'Clear'),
          ),
        ],
      ),
    );
  }

  // App Info Dialog
  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.grey),
            const SizedBox(width: 8),
            Text(widget.isSinhala ? 'යෙදුම් තොරතුරු' : 'App Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
                      "assets/image.png",
                      width: 120,
                      height: 120,
                    ),
            const SizedBox(height: 16),
            const Text(
              'Motherly',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              '© 2025 Motherly App',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Made with Love 🇱🇰',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'හරි' : 'OK'),
          ),
        ],
      ),
    );
  }

  // Privacy Policy Dialog
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.isSinhala ? 'රහස්‍යතා ප්‍රතිපත්තිය' : 'Privacy Policy'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.privacy_tip, size: 50, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                widget.isSinhala
                    ? 'අපි ඔබගේ පුද්ගලික තොරතුරු ආරක්ෂා කරන අතර කිසිදු තෙවන පාර්ශ්වයක් සමඟ බෙදා නොගනිමු.'
                    : 'We protect your personal information and do not share it with any third parties.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'හරි' : 'OK'),
          ),
        ],
      ),
    );
  }

  // Logout Confirmation
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            const SizedBox(width: 8),
            Text(widget.isSinhala ? 'ඉවත් වන්න' : 'Logout'),
          ],
        ),
        content: Text(
          widget.isSinhala
              ? 'ඔබට ඉවත් වීමට අවශ්‍යද?'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'නැත' : 'No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                setState(() => _isLoading = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isSinhala ? 'ඔව්' : 'Yes'),
          ),
        ],
      ),
    );
  }

  // ==================== ACCOUNT DEACTIVATION ====================

  void _showDeactivateConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isSinhala ? 'ගිණුම අක්‍රිය කරන්නද?' : 'Deactivate Account?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isSinhala
                  ? 'මෙය ඔබගේ ගිණුම සහ සියලුම දත්ත ස්ථිරවම මකා දමනු ඇත:'
                  : 'This will permanently delete your account and all data:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDeactivationItem(
                    icon: Icons.baby_changing_station,
                    text: widget.isSinhala ? 'දරුවාගේ තොරතුරු' : 'Baby information',
                  ),
                  const Divider(height: 8),
                  _buildDeactivationItem(
                    icon: Icons.calendar_month,
                    text: widget.isSinhala ? 'එන්නත් වාර්තා' : 'Vaccination records',
                  ),
                  const Divider(height: 8),
                  _buildDeactivationItem(
                    icon: Icons.notifications,
                    text: widget.isSinhala ? 'මතක් කිරීම්' : 'Reminders',
                  ),
                  const Divider(height: 8),
                  _buildDeactivationItem(
                    icon: Icons.event,
                    text: widget.isSinhala ? 'දින දර්ශන සිදුවීම්' : 'Calendar events',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isSinhala
                  ? 'මෙම ක්‍රියාව ආපසු හැරවිය නොහැක!'
                  : 'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.isSinhala ? 'එපා' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordVerification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.isSinhala ? 'ඉදිරියට' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeactivationItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _showPasswordVerification() {
    final passwordController = TextEditingController();
    final reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            widget.isSinhala ? 'අවසන් තහවුරු කිරීම' : 'Final Verification',
            style: const TextStyle(color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Password field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.isSinhala ? 'මුරපදය' : 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Reason for leaving (optional)
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: widget.isSinhala ? 'ඉවත් වීමට හේතුව (විකල්ප)' : 'Reason for leaving (optional)',
                  prefixIcon: const Icon(Icons.feedback, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Warning text
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isSinhala
                            ? 'මුරපදය ඇතුළත් කිරීමෙන් පසු ඔබගේ ගිණුම ස්ථිරවම මකනු ඇත'
                            : 'Entering your password will permanently delete your account',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.isSinhala ? 'අවලංගු කරන්න' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.isSinhala 
                                  ? 'කරුණාකර මුරපදය ඇතුළත් කරන්න' 
                                  : 'Please enter your password',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      setState(() => isLoading = true);
                      
                      try {
                        // Re-authenticate user
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          final credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: passwordController.text,
                          );
                          
                          await user.reauthenticateWithCredential(credential);
                          
                          // Delete all user data
                          await _deleteUserData();
                          
                          // Save feedback if provided
                          if (reasonController.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('deactivation_feedback')
                                .add({
                                  'userId': user.uid,
                                  'reason': reasonController.text,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                          }
                          
                          // Delete the user account
                          await user.delete();
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            _showGoodbyeDialog();
                          }
                        }
                      } on FirebaseAuthException catch (e) {
                        setState(() => isLoading = false);
                        
                        String message = e.code == 'wrong-password'
                            ? (widget.isSinhala ? 'වැරදි මුරපදයක්' : 'Wrong password')
                            : (widget.isSinhala ? 'දෝෂයකි' : 'Error: ${e.code}');
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.isSinhala ? 'ගිණුම මකන්න' : 'Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // 1. Delete all calendar events for this infant
      final events = await _firestoreService.getInfantEvents(widget.infant.infantId);
      for (var event in events) {
        await _firestoreService.deleteCalendarEvent(event.eventId);
      }
      
      // 2. Delete all vaccinations
      final vaccinations = await _firestoreService.getVaccinations(widget.infant.infantId);
      for (var vac in vaccinations) {
        await FirebaseFirestore.instance
            .collection('infant_vaccinations')
            .doc(vac.id)
            .delete();
      }
      
      // 3. Delete infant document
      await FirebaseFirestore.instance
          .collection('infants')
          .doc(widget.infant.infantId)
          .delete();
      
      // 4. Delete user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  void _showGoodbyeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                color: Colors.purple.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isSinhala ? 'ඔබව නැවත හමුවනතුරු' : 'Goodbye for now',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          widget.isSinhala
              ? 'ඔබගේ ගිණුම සාර්ථකව මකා දමන ලදී. ඔබව නැවත පිළිගැනීමට අපි සැමවිටම සූදානම්.'
              : 'Your account has been successfully deleted. We\'re always here when you need us again.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => WelcomeScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.isSinhala ? 'හරි' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _updateNotificationSettings() {
    // TODO: Implement notification settings update
    // This would update Firestore with user's notification preferences
    print('Notification settings updated');
  }
}