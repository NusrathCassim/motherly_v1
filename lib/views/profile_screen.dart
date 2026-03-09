import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:motherly_v1/models/user_model.dart';
import 'package:motherly_v1/models/infant_model.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';


class ProfileScreen extends StatefulWidget {
  final bool isSinhala;
  final UserModel user;
  final InfantModel infant;

  const ProfileScreen({
    super.key,
    required this.isSinhala,
    required this.user,
    required this.infant,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSendingVerification = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    // Set initial values from user model
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email ?? '';
    _phoneController.text = widget.user.phoneNumber ?? '';
    _addressController.text = widget.user.address ?? '';
    
    // Check email verification status
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Theme color based on infant gender
  Color get _themeColor {
    final gender = widget.infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue;
    }
    return Colors.pink;
  }

  Color get _lightThemeColor => _themeColor.withOpacity(0.1);

  Future<void> _checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      setState(() {
        _isEmailVerified = user.emailVerified;
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isSendingVerification = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        if (mounted) {
          _showSuccessSnackBar(
            widget.isSinhala
                ? 'තහවුරු කිරීමේ ඊමේල් එකක් යවන ලදී. කරුණාකර ඔබගේ ඊමේල් පරීක්ෂා කරන්න.'
                : 'Verification email sent. Please check your inbox.'
          );
          
          // Show dialog with instructions
          _showVerificationDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          widget.isSinhala
              ? 'තහවුරු කිරීමේ ඊමේල් එක යැවීමට අපොහොසත් විය: $e'
              : 'Failed to send verification email: $e'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVerification = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final isVerified = user.emailVerified;
        
        setState(() {
          _isEmailVerified = isVerified;
        });

        if (isVerified) {
          _showSuccessSnackBar(
            widget.isSinhala
                ? 'ඔබගේ ඊමේල් ලිපිනය සාර්ථකව තහවුරු කර ඇත!'
                : 'Your email has been successfully verified!'
          );
        } else {
          _showErrorSnackBar(
            widget.isSinhala
                ? 'ඊමේල් ලිපිනය තවමත් තහවුරු කර නොමැත. කරුණාකර ඔබගේ ඊමේල් පරීක්ෂා කර නැවත උත්සාහ කරන්න.'
                : 'Email not verified yet. Please check your inbox and try again.'
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        widget.isSinhala
            ? 'තහවුරු කිරීමේ තත්ත්වය පරීක්ෂා කිරීමට අපොහොසත් විය'
            : 'Failed to check verification status'
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.mark_email_read, color: _themeColor),
              const SizedBox(width: 8),
              Text(
                widget.isSinhala ? 'ඊමේල් තහවුරු කිරීම' : 'Email Verification',
                style: TextStyle(
                  color: _themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_unread,
                size: 60,
                color: _themeColor,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isSinhala
                    ? 'අපි ඔබගේ ඊමේල් ලිපිනයට තහවුරු කිරීමේ සබැඳියක් යවා ඇත. කරුණාකර ඔබගේ ඊමේල් පරීක්ෂා කර ඔබගේ ගිණුම තහවුරු කරන්න.'
                    : 'We have sent a verification link to your email address. Please check your email and verify your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSinhala
                    ? 'තහවුරු කිරීමෙන් පසු, පහත "තත්ත්වය පරීක්ෂා කරන්න" බොත්තම ඔබන්න.'
                    : 'After verification, click the "Check Status" button below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.isSinhala ? 'පසුව' : 'Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkVerificationStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.isSinhala ? 'තත්ත්වය පරීක්ෂා කරන්න' : 'Check Status',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    // Validate required fields
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar(
        widget.isSinhala 
            ? 'කරුණාකර නම ඇතුළත් කරන්න' 
            : 'Please enter your name'
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the user in Firestore
      final updatedData = {
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
      };
      
      await _firestoreService.updateUserFields(widget.user.id, updatedData);
      
      // Show success message
      if (mounted) {
        _showSuccessSnackBar(
          widget.isSinhala 
              ? 'වෙනස්කම් සාර්ථකව සුරකින ලදී' 
              : 'Changes saved successfully'
        );
        
        // Return the updated data to the previous screen
        Navigator.pop(context, {
          'name': _nameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          widget.isSinhala 
              ? 'දෝෂයක් සිදු විය: $e' 
              : 'Error saving changes: $e'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isSinhala ? 'පැතිකඩ සංස්කරණය' : 'Edit Profile',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _themeColor,
                    ),
                  )
                : Text(
                    widget.isSinhala ? 'සුරකින්න' : 'Save',
                    style: TextStyle(
                      color: _themeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Image Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _themeColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: _lightThemeColor,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _themeColor,
                    ),
                  ),
                ),
              ),
            ),

            // Personal Information Section
            _buildSection(
              title: widget.isSinhala ? 'පුද්ගලික තොරතුරු' : 'Personal Information',
              children: [
                _buildTextField(
                  label: widget.isSinhala ? 'සම්පූර්ණ නම' : 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  isRequired: true,
                ),
                
                // Email field with verification status
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false,
                      ),
                      const SizedBox(height: 8),
                      // Email verification section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isEmailVerified 
                              ? Colors.green.shade50 
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isEmailVerified 
                                ? Colors.green.shade200 
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isEmailVerified 
                                  ? Icons.verified 
                                  : Icons.warning_amber_rounded,
                              color: _isEmailVerified 
                                  ? Colors.green 
                                  : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEmailVerified
                                        ? (widget.isSinhala 
                                            ? 'ඊමේල් තහවුරු කර ඇත' 
                                            : 'Email Verified')
                                        : (widget.isSinhala 
                                            ? 'ඊමේල් තහවුරු කර නොමැත' 
                                            : 'Email Not Verified'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _isEmailVerified 
                                          ? Colors.green.shade800 
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  if (!_isEmailVerified)
                                    Text(
                                      widget.isSinhala
                                          ? 'කරුණාකර ඔබගේ ඊමේල් ලිපිනය තහවුරු කරන්න'
                                          : 'Please verify your email address',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!_isEmailVerified)
                              ElevatedButton(
                                onPressed: _isSendingVerification 
                                    ? null 
                                    : _sendVerificationEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _themeColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 8,
                                  ),
                                ),
                                child: _isSendingVerification
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        widget.isSinhala 
                                            ? 'තහවුරු කරන්න' 
                                            : 'Verify',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.isSinhala ? 'තහවුරුයි' : 'Verified',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!_isEmailVerified)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: _checkVerificationStatus,
                            child: Text(
                              widget.isSinhala
                                  ? 'තහවුරු කිරීමේ තත්ත්වය පරීක්ෂා කරන්න'
                                  : 'Check verification status',
                              style: TextStyle(
                                color: _themeColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                _buildTextField(
                  label: widget.isSinhala ? 'දුරකථන අංකය' : 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  prefix: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+94',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                _buildTextField(
                  label: widget.isSinhala ? 'ලිපිනය' : 'Address',
                  controller: _addressController,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isSinhala ? 'වෙනස්කම් සුරකින්න' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffix,
    Widget? prefix,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: maxLines > 1 ? 70 : 50,
            decoration: BoxDecoration(
              color: _lightThemeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(icon, color: _themeColor, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade400,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (prefix != null) ...[
                        prefix,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          enabled: enabled,
                          maxLines: maxLines,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: enabled ? Colors.black : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (suffix != null) suffix,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}