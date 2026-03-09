import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';
import 'package:motherly_v1/models/infant_model.dart';
import 'package:motherly_v1/models/growth_record_model.dart';
import 'package:motherly_v1/widgets/growth_chart.dart';

class WeightTrackingScreen extends StatefulWidget {
  final bool isSinhala;
  final String infantId;
  final String infantName;

  const WeightTrackingScreen({
    super.key,
    required this.isSinhala,
    required this.infantId,
    required this.infantName,
  });

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _weightController = TextEditingController();
  
  InfantModel? _infant;
  List<GrowthRecord> _userRecords = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _infant = await _firestoreService.getInfant(widget.infantId);
    
    if (_infant != null) {
      _userRecords = await _firestoreService.getGrowthRecords(widget.infantId);
    }
    
    setState(() => _isLoading = false);
  }

  List<GrowthRecord> _getAllRecords() {
    if (_infant == null) return [];
    
    final birthRecord = GrowthRecord(
      id: 'birth_${_infant!.infantId}',
      infantId: _infant!.infantId,
      date: _infant!.dateOfBirth,
      weight: _infant!.weight ?? 0,
      ageInMonths: 0,
      isBirthRecord: true,
    );
    
    return [birthRecord, ..._userRecords];
  }

  int _calculateAgeInMonths(DateTime birthDate, DateTime currentDate) {
    int months = (currentDate.year - birthDate.year) * 12;
    months += currentDate.month - birthDate.month;
    
    if (currentDate.day < birthDate.day) {
      months--;
    }
    
    return months;
  }

  Future<void> _saveWeight() async {
    if (_weightController.text.isEmpty || _infant == null) return;
    
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;
    
    final ageInMonths = _calculateAgeInMonths(_infant!.dateOfBirth, _selectedDate);
    
    final newRecord = GrowthRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      infantId: _infant!.infantId,
      date: _selectedDate,
      weight: weight,
      ageInMonths: ageInMonths,
    );
    
    setState(() {
      _userRecords.add(newRecord);
    });
    
    _weightController.clear();
    _selectedDate = DateTime.now();
    
    try {
      await _firestoreService.addGrowthRecord(newRecord);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isSinhala ? 'බර සටහන් කරන ලදී' : 'Weight recorded',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _userRecords.removeWhere((r) => r.id == newRecord.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isSinhala ? 'දෝෂයකි: සුරැකිය නොහැක' : 'Error: Could not save',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isSinhala ? 'තහවුරු කරන්න' : 'Confirm'),
        content: Text(
          widget.isSinhala
              ? 'මෙම මිනුම මකා දැමීමට අවශ්‍යද?'
              : 'Delete this measurement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.isSinhala ? 'නැහැ' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(widget.isSinhala ? 'මකන්න' : 'Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _userRecords.removeWhere((r) => r.id == recordId);
      });
      
      await _firestoreService.deleteGrowthRecord(recordId);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _infant?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // History Modal
  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                const SizedBox(height: 16),
                
                // Title
                Text(
                  widget.isSinhala ? 'බර ඉතිහාසය' : 'Weight History',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.infantName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Birth weight info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isSinhala ? 'උපත් බර' : 'Birth Weight',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_infant?.weight?.toStringAsFixed(1) ?? '0'} kg',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Records list
                Expanded(
                  child: _userRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isSinhala
                                    ? 'තවමත් වාර්තා නැත'
                                    : 'No records yet',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _userRecords.length,
                          itemBuilder: (context, index) {
                            final record = _userRecords.reversed.toList()[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    '${record.ageInMonths}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  DateFormat('yyyy-MM-dd').format(record.date),
                                ),
                                subtitle: Text(
                                  '${record.weight.toStringAsFixed(1)} kg • ${record.ageInMonths} ${widget.isSinhala ? 'මාස' : 'months'}',
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade400,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context); // Close modal
                                    await _deleteRecord(record.id);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isSinhala ? 'බර නිරීක්ෂණය' : 'Weight Tracking'),
          backgroundColor: Colors.blue.shade400,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_infant == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isSinhala ? 'බර නිරීක්ෂණය' : 'Weight Tracking'),
          backgroundColor: Colors.blue.shade400,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                widget.isSinhala
                    ? 'දරුවාගේ තොරතුරු සොයාගත නොහැක'
                    : 'Infant information not found',
              ),
            ],
          ),
        ),
      );
    }

    final allRecords = _getAllRecords();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSinhala ? 'බර නිරීක්ෂණය' : 'Weight Tracking',
        ),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        actions: [
          // History button - only enabled if there are records
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _userRecords.isEmpty ? null : _showHistoryModal,
            tooltip: widget.isSinhala ? 'ඉතිහාසය' : 'History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: widget.isSinhala ? 'නැවුම් කරන්න' : 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isSinhala
                          ? 'නව බර සටහන් කරන්න'
                          : 'Record New Weight',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Date selector
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade400),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Weight input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: widget.isSinhala ? 'බර (kg)' : 'Weight (kg)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveWeight,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          child: Text(
                            widget.isSinhala ? 'සුරකින්න' : 'Save',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Growth Chart
            Container(
              height: 600,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GrowthChartWidget(
                    records: allRecords,
                    isSinhala: widget.isSinhala,
                    gender: _infant!.gender ?? 'boy',
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }
}