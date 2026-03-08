import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';
import 'package:motherly_v1/models/vaccination_model.dart';
import 'package:motherly_v1/models/infant_model.dart';

class ReminderScreen extends StatefulWidget {
  final bool isSinhala;
  final String infantId;
  final String infantName;
  final InfantModel? infant;

  const ReminderScreen({
    super.key,
    required this.isSinhala,
    required this.infantId,
    required this.infantName,
    this.infant,
  });

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<VaccinationModel> _vaccinations = [];
  bool _isLoading = true;
  String? _errorMessage;
  InfantModel? _infant; 
  
  int _selectedFilterIndex = 0;
  late TabController _tabController;
  
  // Theme color based on baby's gender
  Color get _themeColor {
    if (_infant == null) {
      debugPrint('_infant is null, returning default pink');
      return Colors.pink;
    }
    final gender = _infant!.gender?.toLowerCase() ?? '';
    debugPrint('Determining theme color for gender: "$gender"');
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      debugPrint('→ Returning BLUE');
      return Colors.blue;
    }
    debugPrint('→ Returning PINK');
    return Colors.pink;
  }

  // Background color based on gender
  Color get _backgroundColor {
    if (_infant == null) return Colors.pink.shade50;
    final gender = _infant!.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue.shade50;
    }
    return Colors.pink.shade50;
  }

  Color get _lightThemeColor => _themeColor.withOpacity(0.1);
  Color get _veryLightThemeColor => _themeColor.withOpacity(0.05);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadData(); // Load both infant and vaccinations
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedFilterIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load infant data first (for gender theming)
      if (widget.infant != null) {
        _infant = widget.infant;
        debugPrint('Using provided infant: ${_infant?.name}, gender: ${_infant?.gender}');
      } else {
        debugPrint('Fetching infant with ID: ${widget.infantId}');
        _infant = await _firestoreService.getInfant(widget.infantId);
        debugPrint('Fetched infant: ${_infant?.name}, gender: ${_infant?.gender}');
      }
      
      // Then load vaccinations
      debugPrint('Fetching vaccinations for infant: ${widget.infantId}');
      final vaccinations = await _firestoreService.getVaccinations(widget.infantId);
      debugPrint('Fetched ${vaccinations.length} vaccinations');
      
      setState(() {
        _vaccinations = vaccinations;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVaccinationStatus(VaccinationModel vaccination, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (newStatus == 'completed' ? Colors.green : _lightThemeColor).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                newStatus == 'completed' ? Icons.check_circle : Icons.refresh,
                color: newStatus == 'completed' ? Colors.green : _themeColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              newStatus == 'completed'
                  ? (widget.isSinhala ? 'තහවුරු කරන්න' : 'Confirm')
                  : (widget.isSinhala ? 'නැවත විවෘත කරන්න' : 'Reopen'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          newStatus == 'completed'
              ? (widget.isSinhala
                  ? '${vaccination.vaccineName} එන්නත ලබා දුන් බව සටහන් කරන්නද?'
                  : 'Mark ${vaccination.vaccineName} as completed?')
              : (widget.isSinhala
                  ? '${vaccination.vaccineName} එන්නත නැවත විවෘත කරන්නද?'
                  : 'Reopen ${vaccination.vaccineName}?'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: Text(widget.isSinhala ? 'නැහැ' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'completed' ? Colors.green : _themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.isSinhala ? 'ඔව්' : 'Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final updatedVaccination = VaccinationModel(
        id: vaccination.id,
        infantId: vaccination.infantId,
        vaccineName: vaccination.vaccineName,
        scheduledDate: vaccination.scheduledDate,
        status: newStatus,
      );

      await _firestoreService.updateVaccinationStatus(updatedVaccination);
      await _loadData(); // Refresh all data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'completed' ? Icons.check_circle : Icons.refresh,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newStatus == 'completed'
                        ? (widget.isSinhala ? 'එන්නත සම්පූර්ණ කරන ලදී' : 'Vaccination completed')
                        : (widget.isSinhala ? 'එන්නත නැවත විවෘත කරන ලදී' : 'Vaccination reopened'),
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus == 'completed' ? Colors.green : _themeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSinhala ? 'දෝෂයකි: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<VaccinationModel> get _filteredVaccinations {
    final now = DateTime.now();
    
    switch (_selectedFilterIndex) {
      case 0: // All
        return _vaccinations..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      
      case 1: // Pending (overdue + today)
        return _vaccinations
            .where((v) => v.status == 'pending' && !v.scheduledDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      
      case 2: // Upcoming
        return _vaccinations
            .where((v) => v.status == 'pending' && v.scheduledDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      
      case 3: // Completed
        return _vaccinations
            .where((v) => v.status == 'completed')
            .toList()
          ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      
      default:
        return _vaccinations;
    }
  }

  int _getFilterCount(int index) {
    final now = DateTime.now();
    switch (index) {
      case 0: return _vaccinations.length;
      case 1: return _vaccinations.where((v) => v.status == 'pending' && !v.scheduledDate.isAfter(now)).length;
      case 2: return _vaccinations.where((v) => v.status == 'pending' && v.scheduledDate.isAfter(now)).length;
      case 3: return _vaccinations.where((v) => v.status == 'completed').length;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isSinhala ? 'මතක් කිරීම්' : 'Reminders',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _lightThemeColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: _themeColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightThemeColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: _themeColor, size: 20),
              onPressed: _loadData,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _lightThemeColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: _themeColor,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                _buildFilterTab(0, Icons.list, 'සියල්ල', 'All'),
                _buildFilterTab(1, Icons.warning, 'බලාපොරොත්තු', 'Pending'),
                _buildFilterTab(2, Icons.schedule, 'ඉදිරියේදී', 'Upcoming'),
                _buildFilterTab(3, Icons.check_circle, 'සම්පූර්ණ', 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : _vaccinations.isEmpty
                  ? _buildEmptyWidget()
                  : _buildVaccinationList(),
    );
  }

Tab _buildFilterTab(int index, IconData icon, String sinhalaLabel, String englishLabel) {
  return Tab(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // ← ADD PADDING HERE
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 10), // Slightly reduced from 10 to 8
          Text(
            widget.isSinhala ? sinhalaLabel : englishLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (_getFilterCount(index) > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: _selectedFilterIndex == index ? Colors.white : _getBadgeColor(index),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${_getFilterCount(index)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: _selectedFilterIndex == index ? _getBadgeColor(index) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
  Color _getBadgeColor(int index) {
    switch (index) {
      case 1: return Colors.orange;
      case 2: return _themeColor;
      case 3: return Colors.green;
      default: return _themeColor;
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(widget.isSinhala ? 'නැවත උත්සාහ කරන්න' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _lightThemeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy, size: 64, color: _themeColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isSinhala ? 'එන්නත් වාර්තා නැත' : 'No vaccination records',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isSinhala
                  ? 'ඔබගේ දරුවාගේ එන්නත් වාර්තා මෙහි දිස්වනු ඇත'
                  : 'Your baby\'s vaccination records will appear here',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinationList() {
    final filtered = _filteredVaccinations;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              widget.isSinhala
                  ? 'මෙම කාණ්ඩයේ එන්නත් නැත'
                  : 'No vaccinations in this category',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final vaccination = filtered[index];
        return _buildVaccinationCard(vaccination);
      },
    );
  }

  Widget _buildVaccinationCard(VaccinationModel vaccination) {
    final isClickable = vaccination.status == 'completed' ||
        (vaccination.status == 'pending' && !vaccination.scheduledDate.isAfter(DateTime.now()));
    final isUpcoming = vaccination.status == 'pending' && vaccination.scheduledDate.isAfter(DateTime.now());
    final isOverdue = vaccination.status == 'pending' && vaccination.scheduledDate.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isClickable ? 2 : 0,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: InkWell(
          onTap: isClickable ? () {
            if (vaccination.status == 'completed') {
              _updateVaccinationStatus(vaccination, 'pending');
            } else {
              _updateVaccinationStatus(vaccination, 'completed');
            }
          } : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUpcoming ? Colors.grey.shade200 : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor(vaccination.status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(vaccination),
                        color: _getStatusColor(vaccination.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vaccination.vaccineName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isUpcoming ? Colors.grey.shade500 : Colors.grey.shade900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(vaccination.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(vaccination.status, widget.isSinhala),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getStatusColor(vaccination.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: isUpcoming ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('yyyy-MM-dd').format(vaccination.scheduledDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUpcoming ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDaysUntilText(vaccination.scheduledDate, widget.isSinhala),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? Colors.red.shade400
                                      : isUpcoming
                                          ? Colors.grey.shade400
                                          : _themeColor,
                                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (isUpcoming) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isSinhala
                                ? 'මෙම එන්නත ලබා ගැනීමට නියමිත දිනය තෙක් රැඳී සිටින්න'
                                : 'Locked until scheduled date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isSinhala
                                ? 'එන්නත ලබා ගැනීමට නියමිත දිනය ඉකුත්වී ඇත. හැකි ඉක්මනින් ලබා ගන්න.'
                                : 'Vaccination is overdue. Please schedule as soon as possible.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(VaccinationModel vaccination) {
    if (vaccination.status == 'completed') {
      return Icons.check_circle;
    } else if (vaccination.isOverdue) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.schedule;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return _themeColor;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, bool isSinhala) {
    switch (status) {
      case 'completed':
        return isSinhala ? 'සම්පූර්ණයි' : 'Completed';
      case 'pending':
        return isSinhala ? 'බලාපොරොත්තු' : 'Pending';
      case 'missed':
        return isSinhala ? 'මඟ හැරුණි' : 'Missed';
      default:
        return status;
    }
  }

  String _getDaysUntilText(DateTime scheduledDate, bool isSinhala) {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now).inDays;
    
    if (difference == 0) {
      return isSinhala ? 'අද' : 'Today';
    } else if (difference > 0) {
      return isSinhala ? 'දින $difference කින්' : 'in $difference days';
    } else {
      return isSinhala ? 'දින ${-difference} කට පෙර' : '${-difference} days ago';
    }
  }
}