// calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:motherly_v1/models/calender_event_modal.dart';
import 'package:motherly_v1/models/infant_model.dart';

class CalendarScreen extends StatefulWidget {
  final bool isSinhala;
  final String infantId;
  final String infantName;
  final InfantModel infant;// Add gender parameter

  const CalendarScreen({
    Key? key,
    required this.isSinhala,
    required this.infantId,
    required this.infantName,
    required this.infant,// Make it optional but we'll pass it
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<CalendarEventModel> _events = [];
  List<CalendarEventModel> _selectedDateEvents = [];
  bool _isLoading = false;

  // Get theme color based on baby's gender
  Color get _themeColor {
     final gender = widget.infant.gender?.toLowerCase() ?? '';
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
    final gender = widget.infant.gender?.toLowerCase() ?? '';
    if (gender == 'boy' || gender == 'male' || gender == 'පිරිමි') {
      return Colors.blue.shade50; // Light blue for boys
    }
    return Colors.pink.shade50; // Light pink for girls
  }

  // Cute icon options for baby events (with theme colors for selection)
  final List<Map<String, dynamic>> _cuteIcons = [
    {'icon': '🐻', 'name': 'Teddy Bear', 'color': Colors.brown},
    {'icon': '🍼', 'name': 'Baby Bottle', 'color': Colors.blue},
    {'icon': '🧸', 'name': 'Teddy', 'color': Colors.amber},
    {'icon': '🎂', 'name': 'Birthday', 'color': Colors.pink},
    {'icon': '✨', 'name': 'Sparkles', 'color': Colors.purple},
    {'icon': '🦷', 'name': 'Tooth', 'color': Colors.grey},
    {'icon': '👶', 'name': 'Baby', 'color': Colors.orange},
    {'icon': '💤', 'name': 'Sleep', 'color': Colors.indigo},
    {'icon': '🥣', 'name': 'Feeding', 'color': Colors.green},
    {'icon': '🏥', 'name': 'Doctor', 'color': Colors.red},
    {'icon': '🎀', 'name': 'Bow', 'color': Colors.pinkAccent},
    {'icon': '🚼', 'name': 'Baby Symbol', 'color': Colors.lightBlue},
    {'icon': '🍭', 'name': 'Lollipop', 'color': Colors.deepPurple},
    {'icon': '🧁', 'name': 'Cupcake', 'color': Colors.pink},
    {'icon': '🪀', 'name': 'Toy', 'color': Colors.teal},
    {'icon': '📸', 'name': 'Photo', 'color': Colors.cyan},
    {'icon': '🎵', 'name': 'Lullaby', 'color': Colors.deepPurple},
    {'icon': '🌙', 'name': 'Goodnight', 'color': Colors.indigo[900]!},
    {'icon': '☀️', 'name': 'Sunshine', 'color': Colors.amber},
    {'icon': '🦋', 'name': 'Butterfly', 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _loadMonthEvents();
  }

  Future<void> _loadMonthEvents() async {
    setState(() => _isLoading = true);
    try {
      _events = await _firestoreService.getMonthEvents(widget.infantId, _currentMonth);
      _updateSelectedDateEvents();
    } catch (e) {
      print('Error loading events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSinhala ? 'දෝෂයකි' : 'Error loading events'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateSelectedDateEvents() {
    _selectedDateEvents = _events.where((event) {
      return event.eventDate.year == _selectedDate.year &&
             event.eventDate.month == _selectedDate.month &&
             event.eventDate.day == _selectedDate.day;
    }).toList();
  }

  void _showAddEventBottomSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedEventDate = _selectedDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    String selectedIcon = '📝';
    Color selectedColor = Colors.pink;
    String selectedEventType = 'custom';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Curved top handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Header with theme color
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _lightThemeColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: _themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.isSinhala ? 'නව සිදුවීම' : 'Add New Event',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        _buildInputField(
                          controller: titleController,
                          label: widget.isSinhala ? 'මාතෘකාව' : 'Title',
                          icon: Icons.title,
                          hint: widget.isSinhala 
                              ? 'උදා: පළමු වතාවට හිනාවුණා' 
                              : 'E.g: First smile',
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        _buildInputField(
                          controller: descriptionController,
                          label: widget.isSinhala ? 'විස්තරය' : 'Description',
                          icon: Icons.description,
                          maxLines: 3,
                          hint: widget.isSinhala 
                              ? 'විස්තර එකතු කරන්න...' 
                              : 'Add details...',
                        ),
                        const SizedBox(height: 16),
                        
                        // Date and Time
                        Text(
                          widget.isSinhala ? 'දිනය සහ වේලාව' : 'Date & Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _themeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildPickerTile(
                                icon: Icons.calendar_today,
                                label: DateFormat('yyyy-MM-dd').format(selectedEventDate),
                                color: _themeColor,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedEventDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: _themeColor,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedEventDate = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        selectedEventDate.hour,
                                        selectedEventDate.minute,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPickerTile(
                                icon: Icons.access_time,
                                label: selectedTime.format(context),
                                color: _themeColor,
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: _themeColor,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedTime = picked;
                                      selectedEventDate = DateTime(
                                        selectedEventDate.year,
                                        selectedEventDate.month,
                                        selectedEventDate.day,
                                        picked.hour,
                                        picked.minute,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Event Type
                        Text(
                          widget.isSinhala ? 'සිදුවීම් වර්ගය' : 'Event Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _themeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _themeColor.withOpacity(0.3)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedEventType,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: _themeColor),
                            items: [
                              DropdownMenuItem(
                                value: 'nap', 
                                child: Row(
                                  children: [
                                    const Text('💤 '),
                                    Text(widget.isSinhala ? 'නින්ද' : 'Nap'),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: 'feeding', 
                                child: Row(
                                  children: [
                                    const Text('🍼 '),
                                    Text(widget.isSinhala ? 'පෝෂණය' : 'Feeding'),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: 'milestone', 
                                child: Row(
                                  children: [
                                    const Text('✨ '),
                                    Text(widget.isSinhala ? 'සන්ධිස්ථානය' : 'Milestone'),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: 'appointment', 
                                child: Row(
                                  children: [
                                    const Text('🏥 '),
                                    Text(widget.isSinhala ? 'වෛද්‍ය හමුවීම' : 'Appointment'),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: 'custom', 
                                child: Row(
                                  children: [
                                    const Text('📝 '),
                                    Text(widget.isSinhala ? 'වෙනත්' : 'Custom'),
                                  ],
                                )
                              ),
                            ],
                            onChanged: (value) {
                              setSheetState(() {
                                selectedEventType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Cute Icon Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isSinhala ? 'අයිකනය තෝරන්න' : 'Choose Icon',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _themeColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: selectedColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedIcon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: selectedColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _themeColor.withOpacity(0.2)),
                          ),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 1,
                            ),
                            itemCount: _cuteIcons.length,
                            itemBuilder: (context, index) {
                              final iconData = _cuteIcons[index];
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedIcon = iconData['icon'];
                                    selectedColor = iconData['color'];
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: selectedIcon == iconData['icon']
                                        ? _themeColor.withOpacity(0.2)
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    border: selectedIcon == iconData['icon']
                                        ? Border.all(color: _themeColor, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      iconData['icon'],
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            widget.isSinhala ? 'අවලංගු කරන්න' : 'Cancel',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.isSinhala 
                                        ? 'කරුණාකර මාතෘකාවක් ඇතුළත් කරන්න' 
                                        : 'Please enter a title',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            final event = CalendarEventModel(
                              eventId: '',
                              infantId: widget.infantId,
                              title: titleController.text,
                              description: descriptionController.text,
                              eventDate: selectedEventDate,
                              eventType: selectedEventType,
                              iconType: selectedIcon,
                              color: selectedColor,
                            );
                            
                            try {
                              await _firestoreService.addCalendarEvent(event);
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadMonthEvents();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.isSinhala 
                                          ? '✅ සිදුවීම එක් කරන ලදී' 
                                          : '✅ Event added',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.isSinhala 
                                          ? '❌ දෝෂයකි: ${e.toString()}' 
                                          : '❌ Error: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            widget.isSinhala ? 'සුරකින්න' : 'Save',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEventDetails(CalendarEventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(event.iconType, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: event.color, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('yyyy-MM-dd hh:mm a').format(event.eventDate)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (event.description.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'හරි' : 'OK'),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: _themeColor),
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.isSinhala ? 'තහවුරු කරන්න' : 'Confirm'),
                  content: Text(widget.isSinhala 
                      ? 'මෙම සිදුවීම මකා දමන්නද?' 
                      : 'Delete this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(widget.isSinhala ? 'නැත' : 'No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        widget.isSinhala ? 'ඔව්' : 'Yes',
                        style: TextStyle(color: _themeColor),
                      ),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await _firestoreService.deleteCalendarEvent(event.eventId);
                _loadMonthEvents();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Dynamic background color
      appBar: AppBar(
        title: Text(
          widget.isSinhala ? 'දින දර්ශනය' : 'Calendar',
        ),
        backgroundColor: _themeColor, // Dynamic app bar color
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEventBottomSheet,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
              ),
            )
          : Column(
              children: [
                // Month header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: _themeColor),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                          });
                          _loadMonthEvents();
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: _themeColor),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                          });
                          _loadMonthEvents();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Calendar grid
                Expanded(
                  flex: 2,
                  child: _buildCalendarGrid(),
                ),
                
                // Events for selected day
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: _buildEventsList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: 42, // 6 weeks
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 2; // Adjust for Monday start
        final isCurrentMonth = day > 0 && day <= daysInMonth;
        final date = isCurrentMonth 
            ? DateTime(_currentMonth.year, _currentMonth.month, day)
            : null;
        
        // Get events for this day
        final dayEvents = isCurrentMonth 
            ? _events.where((e) => 
                e.eventDate.year == date!.year &&
                e.eventDate.month == date.month &&
                e.eventDate.day == date.day
              ).toList()
            : [];
        
        final isSelected = date != null &&
            date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        
        return GestureDetector(
          onTap: isCurrentMonth ? () {
            setState(() {
              _selectedDate = date!;
              _updateSelectedDateEvents();
            });
          } : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected 
                  ? _themeColor.withOpacity(0.2)
                  : isCurrentMonth 
                      ? Colors.white 
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: _themeColor, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCurrentMonth ? day.toString() : '',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentMonth 
                        ? (isSelected ? _themeColor : Colors.black)
                        : Colors.grey,
                  ),
                ),
                if (dayEvents.isNotEmpty)
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: dayEvents.take(3).map((e) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: e.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            e.iconType,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsList() {
    if (_selectedDateEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              widget.isSinhala 
                  ? 'මෙම දිනයේ සිදුවීම් නැත' 
                  : 'No events for this day',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddEventBottomSheet,
              icon: const Icon(Icons.add),
              label: Text(widget.isSinhala ? 'එකතු කරන්න' : 'Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _lightThemeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: _themeColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _themeColor,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: _lightThemeColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: _themeColor),
                  onPressed: _showAddEventBottomSheet,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _selectedDateEvents.length,
            itemBuilder: (context, index) {
              final event = _selectedDateEvents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _themeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _themeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        event.iconType,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormat('hh:mm a').format(event.eventDate),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _lightThemeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: _themeColor,
                      size: 16,
                    ),
                  ),
                  onTap: () => _showEventDetails(event),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method for input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _themeColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _themeColor.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: _themeColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for picker tiles
  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}