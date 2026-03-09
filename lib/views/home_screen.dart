import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:motherly_v1/views/baby_info_screen.dart';
import 'package:motherly_v1/views/article_data.dart';
import 'package:motherly_v1/views/calender_screen.dart';
import 'package:motherly_v1/views/emergency_hospitals_screen.dart';
import 'package:motherly_v1/views/main.dart';
import 'package:motherly_v1/models/calender_event_modal.dart';
import 'package:motherly_v1/views/profile_screen.dart';
import 'package:motherly_v1/views/reminder_screen.dart';
import 'package:motherly_v1/views/scan_screen.dart';
import 'package:motherly_v1/services/firebase_notification_service.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';
import 'package:motherly_v1/models/user_model.dart';
import 'package:motherly_v1/models/infant_model.dart';
import 'package:motherly_v1/models/vaccination_model.dart';
import 'package:intl/intl.dart';
import 'package:motherly_v1/views/setting_screen.dart';
import 'package:motherly_v1/views/weight_tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final String motherId;
  final NotificationService notificationService;

  const HomeScreen({
    super.key, 
    required this.motherId, 
    required this.notificationService
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();
  
  // Data states
  UserModel? _user;
  InfantModel? _infant;
  VaccinationModel? _nextVaccination;
  List<VaccinationModel> _vaccinations = [];
  DateTime? _lastScanDate;
  int _pendingVaccinationsCount = 0;
   Map<String, String> _dailyTip = {};
  // Loading states
  bool _isLoading = true;
  String? _errorMessage;

  // Language preference
  bool get _isSinhala => _user?.language == 'sinhala';

  // Theme color based on baby's gender
  Color get _themeColor {
    if (_infant == null) return Colors.pink; // Default pink
    final gender = _infant!.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue;
    }
    return Colors.pink; // Default for girls
  }

  // Light background color based on gender
  Color get _backgroundColor {
    if (_infant == null) return Colors.pink.shade50;
    final gender = _infant!.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue.shade50; // Light blue for boys
    }
    return Colors.pink.shade50; // Light pink for girls
  }

  // Gradient colors for status card
  List<Color> get _statusGradient {
    if (_infant == null) return [Colors.pink.shade300, Colors.purple.shade300];
    final gender = _infant!.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return [Colors.blue.shade300, Colors.lightBlue.shade300];
    }
    return [Colors.pink.shade300, Colors.purple.shade300];
  }

  // Daily tips with both languages
  
  
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _getLastScanDisplay();
    // Check for due vaccines when app opens
    notificationService.runDailyCheck(widget.motherId);
  });
  }
  // New method to load daily tip from Firestore
  Future<void> _loadDailyTip() async {
    try {
      final tip = await _firestoreService.getDailyTips();
      if (tip.isNotEmpty) {
        setState(() {
          _dailyTip = tip;
        });
      } else {
        // Fallback tips if database is empty
        setState(() {
          _dailyTip = {
            "en": "Talk, sing, and read to your baby every day to support brain development.",
            "si": "දරුවාගේ මොළයේ වර්ධනයට සඳහා නිරන්තරයෙන් දරුවාත් සමග කතා කරන්න, ගී කියන්න, සහ පොත් පෙන්වන්න"
          };
        });
      }
    } catch (e) {
      print('Error loading daily tip: $e');
      // Set fallback tip on error
      setState(() {
        _dailyTip = {
          "en": "Always put baby to sleep on their back to prevent SIDS.",
          "si": "SIDS වැළැක්වීම සඳහා දරුවා නිතරම පිටට හරවා නිදා ගන්න"
        };
      });
    }
  }
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      _user = await _firestoreService.getUser(widget.motherId);
      
      if (_user == null) {
        setState(() {
          _errorMessage = _isSinhala ? 'පරිශීලක හමු නොවීය' : 'User not found';
          _isLoading = false;
        });
        return;
      }
      await _loadDailyTip();
      // Load infant data
      _infant = await _firestoreService.getInfantByMotherId(widget.motherId);
      
      if (_infant != null) {
        // Load vaccinations
        print('INFANT ID : $_infant!.infantId');
        _vaccinations = await _firestoreService.getVaccinations(_infant!.infantId);
        _nextVaccination = await _firestoreService.getNextVaccination(_infant!.infantId);
        _pendingVaccinationsCount = await _firestoreService.getPendingVaccinationsCount(_infant!.infantId);
        _lastScanDate = await _firestoreService.getLastScanDate(_infant!.infantId);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _isSinhala 
            ? 'දත්ත පූරණය කිරීමේ දෝෂයකි: $e' 
            : 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }
   // Method to refresh daily tip (can be called when user wants a new tip)
  Future<void> _refreshDailyTip() async {
    await _loadDailyTip();
  }


  String _getHealthStatus() {
    if (_infant == null) return _isSinhala ? 'දත්ත නැත' : 'No data';
    if (_pendingVaccinationsCount > 2) return _isSinhala ? 'අවධානය අවශ්‍යයි' : 'Need attention';
    if (_nextVaccination?.isOverdue ?? false) return _isSinhala ? 'එන්නත ප්‍රමාද වී ඇත' : 'Vaccination overdue';
    return _isSinhala ? 'හොඳයි' : 'Good';
  }

  Color _getHealthStatusColor() {
    final status = _getHealthStatus();
    if (status == (_isSinhala ? 'හොඳයි' : 'Good')) return Colors.green;
    if (status == (_isSinhala ? 'අවධානය අවශ්‍යයි' : 'Need attention')) return Colors.orange;
    if (status == (_isSinhala ? 'එන්නත ප්‍රමාද වී ඇත' : 'Vaccination overdue')) return Colors.red;
    return Colors.grey;
  }

  String _getLastScanDisplay() {
    if (_lastScanDate == null) return _isSinhala ? 'කවදාවත් නැත' : 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(_lastScanDate!);
    
    if (difference.inDays == 0) {
      return _isSinhala ? 'අද' : 'Today';
    } else if (difference.inDays == 1) {
      return _isSinhala ? 'ඊයේ' : 'Yesterday';
    } else {
      return _isSinhala 
          ? 'දින ${difference.inDays} කට පෙර' 
          : '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Motherly'),
          backgroundColor: _themeColor,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Motherly'),
          backgroundColor: _themeColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                ),
                child: Text(_isSinhala ? 'නැවත උත්සාහ කරන්න' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor, // Dynamic background color
      appBar: AppBar(
        title: const Text(
          'Motherly',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _themeColor, // Dynamic app bar color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.language, 
                  color: Colors.white, 
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _isSinhala ? 'සිංහල' : 'EN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navigate to profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    isSinhala: _isSinhala,
                    user: _user!,
                    infant: _infant!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        color: _backgroundColor, // Force background color
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              
              // Baby Status Card
              _buildBabyStatusCard(),
              const SizedBox(height: 20),
              
              // Feature Grid
              _buildFeatureGrid(context),
              const SizedBox(height: 20),
              
              // Daily Health Tip
              _buildDailyTipCard(),
              const SizedBox(height: 20),
              
              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Welcome Section (with real data)
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSinhala 
                      ? 'ආයුබෝවන්! ${_user?.name ?? 'මව'}'
                      : 'Welcome! ${_user?.name ?? 'Mother'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _themeColor, // Dynamic color
                  ),
                ),
                const SizedBox(height: 4),
                if (_infant != null)
                  Text(
                    _isSinhala
                        ? '${_infant!.name} (${_infant!.ageDisplay})'
                        : '${_infant!.name} (${_infant!.ageDisplayEn})',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  )
                else
                  Text(
                    _isSinhala ? 'දරුවෙක් නැත' : 'No baby registered',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _themeColor.withOpacity(0.1), // Dynamic light color
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.baby_changing_station,
              color: _themeColor, // Dynamic color
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Baby Status Card (with real data)
  Widget _buildBabyStatusCard() {
    final healthStatus = _getHealthStatus();
    final statusColor = _getHealthStatusColor();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _statusGradient, // Dynamic gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: _themeColor.withOpacity(0.3), // Dynamic shadow
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSinhala ? 'දරුවාගේ තත්ත්වය' : 'Baby Status',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem(
                _isSinhala ? 'ඊළඟ එන්නත' : 'Next Vaccine', 
                _nextVaccination != null 
                    ? _isSinhala
                        ? '${_nextVaccination!.vaccineName} (දින ${_nextVaccination!.daysUntil})'
                        : '${_nextVaccination!.vaccineName} (${_nextVaccination!.daysUntil} days)'
                    : _isSinhala ? 'නැත' : 'None'
              ),
              _buildStatusItem(
                _isSinhala ? 'අවසන් පරීක්ෂාව' : 'Last Scan', 
                _getLastScanDisplay()
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _isSinhala ? 'සෞඛ්ය තත්ත්වය: $healthStatus' : 'Health Status: $healthStatus',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 3. Feature Grid (with real badge count)
  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildFeatureCard(
          icon: Icons.camera_alt,
          label: _isSinhala ? 'පරීක්ෂා කරන්න' : 'Scan Baby',
          color: _themeColor, // Dynamic color
          onTap: () {
            if (_infant != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanScreen(
                    isSinhala: _isSinhala,
                    infantId: _infant!.infantId,
                  ),
                ),
              );
            } else {
              _showNoInfantDialog();
            }
          },
        ),
        _buildFeatureCard(
          icon: Icons.notifications,
          label: _isSinhala ? 'මතක් කිරීම්' : 'Reminders',
          color: Colors.orange,
          badge: _pendingVaccinationsCount > 0 ? '$_pendingVaccinationsCount' : null,
          onTap: () {
             if (_infant != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReminderScreen(
                    isSinhala: _isSinhala,
                    infantId: _infant!.infantId,
                    infantName: _infant!.name,
                    infant: _infant!,
                  ),
                ),
              );
            } else {
              _showNoInfantDialog();
            }
          },
        ),
        _buildFeatureCard(
          icon: Icons.emergency,
          label: _isSinhala ? 'හදිසි උදව්' : 'Emergency',
          color: Colors.red,
          onTap: () {
            _showEmergencyDialog(context);
          },
        ),
        _buildFeatureCard(
            icon: Icons.school,
            label: _isSinhala ? 'ඉගෙන ගන්න' : 'Learn',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LearnScreen(
                    isSinhala: _isSinhala,
                    infantId: _infant!.infantId,
                    infantName: _infant!.name,
                    infant: _infant!,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 4. Daily Health Tip
   Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _themeColor.withOpacity(0.3)), // Dynamic border
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isSinhala ? 'Health Tip' : 'Health Tip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _themeColor, // Dynamic color
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSinhala 
                          ? (_dailyTip['si'] ?? 'No tip available') 
                          : (_dailyTip['en'] ?? 'No tip available'),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    if (!_isSinhala && _dailyTip['si'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tip: ${_dailyTip['si']!}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up, color: _themeColor),
                    onPressed: () {
                      _speak(_isSinhala 
                          ? (_dailyTip['si'] ?? 'No tip available') 
                          : (_dailyTip['en'] ?? 'No tip available'));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: _themeColor, size: 20),
                    onPressed: _refreshDailyTip,
                    tooltip: _isSinhala ? 'නව උපදෙසක්' : 'New tip',
                  ),
                ],
              ),
            ],
          ),
          if (_dailyTip.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _isSinhala 
                    ? 'දිනපතා උපදෙස් පූරණය වෙමින්...' 
                    : 'Loading daily tip...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  // 5. Quick Actions
Widget _buildQuickActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section title
      Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(
          _isSinhala ? 'ඉක්මන් ක්‍රියා' : 'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      
      // Quick action buttons row
      Row(
        children: [
          // Calendar Button (your existing button but with navigation)
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.calendar_month,
              label: _isSinhala ? 'දින දර්ශනය' : 'Calendar',
              color: Colors.pink,
              onTap: () {
                if (_infant != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarScreen(
                        isSinhala: _isSinhala,
                        infantId: _infant!.infantId,
                        infantName: _infant!.name,
                        infant: _infant!,
                      ),
                    ),
                  );
                } else {
                  _showNoInfantDialog();
                }
              },
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)), // Dynamic border
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  // Emergency Dialog
// Emergency Dialog
void _showEmergencyDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Hospitals option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _themeColor.withOpacity(0.1),
              child: Icon(Icons.local_hospital, color: _themeColor),
            ),
            title: Text(_isSinhala ? 'අසල රෝහල්' : 'Nearby Hospitals'),
            subtitle: Text(_isSinhala 
                ? 'ඔබට ආසන්නතම රෝහල් සොයා යන්න' 
                : 'Find and navigate to nearby hospitals'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyHospitalsScreen(
                    isSinhala: _isSinhala,
                  ),
                ),
              );
            },
          ),
          
          // Emergency Call option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Icon(Icons.phone, color: Colors.red.shade700),
            ),
            title: Text(
              _isSinhala ? 'හදිසි ඇමතුම්' : 'Emergency Calls',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _isSinhala ? '1990 අමතන්න (ජාතික හදිසි සේවය)' : 'Call 1990 (National Emergency Service)',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                '1990',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            onTap: () {
              // Close the bottom sheet first
              Navigator.pop(context);
              // Then show confirmation dialog
              _showEmergencyCallConfirmation();
            },
          ),
          
          // Police option (optional - can add more)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.local_police, color: Colors.blue.shade700),
            ),
            title: Text(
              _isSinhala ? 'පොලීසිය' : 'Police',
            ),
            subtitle: Text(
              _isSinhala ? '119 අමතන්න' : 'Call 119',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '119',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showEmergencyCallConfirmation(number: '119');
            },
          ),
        ],
      ),
    ),
  );
}

// Show confirmation dialog before making emergency call
void _showEmergencyCallConfirmation({String number = '1990'}) {
  final String serviceName = number == '1990' 
      ? (_isSinhala ? 'ජාතික හදිසි සේවය' : 'National Emergency Service')
      : (_isSinhala ? 'පොලීසිය' : 'Police');
  
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
            _isSinhala ? 'හදිසි ඇමතුම' : 'Emergency Call',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isSinhala
                ? 'ඔබ $serviceName අමතන්නට සූදානම්ද?'
                : 'Are you sure you want to call $serviceName?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSinhala
                ? 'මෙය හදිසි අවස්ථා සඳහා පමණි'
                : 'This is for emergencies only',
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
            _isSinhala ? 'එපා' : 'Cancel',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close confirmation
            _makeEmergencyCall('tel:$number');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isSinhala ? 'අමතන්න' : 'Call Now',
          ),
        ),
      ],
    ),
  );
}

  Future<void> _makeEmergencyCall(String phoneNumber) async {
  try {
    // For emergency numbers, we need to handle differently
    // Just using tel: URI is safer and doesn't require CALL_PHONE permission
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll('tel:', ''),
    );

    // Check if we can launch the phone app
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      
      // Log the call attempt (optional)
      print('Emergency call initiated to $phoneNumber');
    } else {
      // If can't launch, show error
      _showCallError();
    }
  } catch (e) {
    print('Error making call: $e');
    _showCallError();
  }
}

// Show error dialog if call fails
void _showCallError() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Icon(Icons.error_outline, color: Colors.red, size: 40),
      content: Text(
        _isSinhala
            ? 'දුරකථන ඇමතුම ආරම්භ කළ නොහැක. කරුණාකර ඔබගේ උපාංගය පරීක්ෂා කරන්න.'
            : 'Cannot make phone call. Please check your device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isSinhala ? 'හරි' : 'OK'),
        ),
      ],
    ),
  );
}
  // Drawer Navigation
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_themeColor, _themeColor.withOpacity(0.7)], // Dynamic gradient
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: _themeColor), // Dynamic color
                ),
                const SizedBox(height: 10),
                Text(
                  _user?.name ?? (_isSinhala ? 'මව' : 'Mother'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isSinhala ? 'භාෂාව: සිංහල' : 'Language: English',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.home, 
            _isSinhala ? 'මුල් පිටුව' : 'Home', 
            () {
              Navigator.pop(context);
            }
          ),
          _buildDrawerItem(
            Icons.person, 
            _isSinhala ? 'පැතිකඩ' : 'Profile', 
            () {
              Navigator.pop(context);
              // Make sure you have user and infant data available
              if (_user != null && _infant != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      isSinhala: _isSinhala,
                      user: _user!,
                      infant: _infant!,
                    ),
                  ),
                );
              } else {
                // Handle case where data is not available
                _showNoInfantDialog();
              }
            }
          ),
          _buildDrawerItem(
            Icons.baby_changing_station, 
            _isSinhala ? 'දරුවාගේ තොරතුරු' : 'Baby Info', 
            () {
              Navigator.pop(context);
              if (_infant != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BabyInfoScreen(
                      isSinhala: _isSinhala,
                      infant: _infant!,
                    ),
                  ),
                );
              } else {
                _showNoInfantDialog();
              }
            }
          ),
          _buildDrawerItem(
            Icons.notifications, 
              _isSinhala ? 'මතක් කිරීම්' : 'Reminders', 
              () {
                Navigator.pop(context);
                if (_infant != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReminderScreen(
                        isSinhala: _isSinhala,
                        infantId: _infant!.infantId,
                        infantName: _infant!.name,
                        infant: _infant,
                      ),
                    ),
                  );
                } else {
                  _showNoInfantDialog();
                }
              }
          ),
          _buildDrawerItem(
            Icons.settings, 
            _isSinhala ? 'සැකසුම්' : 'Settings', 
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    isSinhala: _isSinhala,
                    user: _user!,
                    infant: _infant!,
                    notificationService: notificationService,
                  ),
                ),
              );  
            }
          ),
          
          // Growth Tracking Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              _isSinhala ? 'වර්ධන නිරීක්ෂණය' : 'Growth Tracking',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Weight Tracking Option
          _buildDrawerItem(
            Icons.monitor_weight, 
            _isSinhala ? 'බර නිරීක්ෂණය' : 'Weight Tracking', 
            () {
              Navigator.pop(context);
              if (_infant != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeightTrackingScreen(
                      isSinhala: _isSinhala,
                      infantId: _infant!.infantId,
                      infantName: _infant!.name,
                    ),
                  ),
                );
              } else {
                _showNoInfantDialog();
              }
            },
          ),
          
          const Divider(),
          
          _buildDrawerItem(
            Icons.logout, 
            _isSinhala ? 'ඉවත් වන්න' : 'Logout', 
            () {
              Navigator.pop(context);
            }
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _themeColor), // Dynamic color
      title: Text(title),
      onTap: onTap,
    );
  }

  void _speak(String text) {
    print('Speaking in ${_isSinhala ? 'Sinhala' : 'English'}: $text');
  }

  void _showNoInfantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(Icons.warning, color: Colors.orange, size: 40),
        content: Text(
          _isSinhala
              ? 'පළමුව දරුවාගේ තොරතුරු එක් කරන්න'
              : 'Please add baby information first',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isSinhala ? 'හරි' : 'OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to add baby screen
            },
            child: Text(
              _isSinhala ? 'දරුවා එක් කරන්න' : 'Add Baby',
              style: TextStyle(color: _themeColor), // Dynamic color
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAddBirthdayDialog() {
  final dateController = TextEditingController();
  DateTime selectedDate = _infant?.dateOfBirth ?? DateTime.now();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Text('🎂'),
          const SizedBox(width: 8),
          Text(_isSinhala ? 'උපන්දිනය එකතු කරන්න' : 'Add Birthday'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.amber),
            title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                selectedDate = picked;
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            _isSinhala 
                ? 'උපන්දින සිහිකැඳවීමක් එක් කරන්නද?' 
                : 'Add a birthday reminder?',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isSinhala ? 'අවලංගු කරන්න' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            
            // Create birthday event
            final event = CalendarEventModel(
              eventId: '',
              infantId: _infant!.infantId,
              title: _isSinhala 
                  ? '${_infant!.name} ගේ උපන්දිනය' 
                  : '${_infant!.name}\'s Birthday',
              description: _isSinhala 
                  ? 'සුභ උපන්දිනයක්! 🎉' 
                  : 'Happy Birthday! 🎉',
              eventDate: selectedDate,
              eventType: 'milestone',
              iconType: '🎂',
              color: Colors.amber,
              isRecurring: true,
              recurringPattern: 'yearly',
            );
            
            try {
              await _firestoreService.addCalendarEvent(event);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSinhala 
                      ? 'උපන්දිනය එකතු කරන ලදී' 
                      : 'Birthday added'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSinhala 
                      ? 'දෝෂයකි' 
                      : 'Error adding birthday'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
          ),
          child: Text(_isSinhala ? 'එකතු කරන්න' : 'Add'),
        ),
      ],
    ),
  );
}
}