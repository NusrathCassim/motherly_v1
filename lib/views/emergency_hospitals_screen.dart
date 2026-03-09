import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:motherly_v1/services/openstreetmap_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart'; // Add this

class EmergencyHospitalsScreen extends StatefulWidget {
  final bool isSinhala;

  const EmergencyHospitalsScreen({super.key, required this.isSinhala});

  @override
  State<EmergencyHospitalsScreen> createState() => _EmergencyHospitalsScreenState();
}

class _EmergencyHospitalsScreenState extends State<EmergencyHospitalsScreen> {
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _findHospitals();
  }

  Future<void> _findHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = widget.isSinhala
              ? 'ස්ථාන සේවාව සක්‍රිය කරන්න'
              : 'Please enable location services';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = widget.isSinhala
                ? 'ස්ථාන අවසරය අවශ්‍යයි'
                : 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      _currentLocation = position;

      // Find hospitals using OpenStreetMap
      final hospitals = await OpenStreetMapService.findNearbyHospitals(position);
      
      setState(() {
        _hospitals = hospitals;
        _isLoading = false;
        
        if (hospitals.isEmpty) {
          _errorMessage = widget.isSinhala
              ? 'අසල රෝහල් හමු නොවීය'
              : 'No hospitals found nearby';
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = widget.isSinhala
            ? 'දෝෂයක්: ${e.toString()}'
            : 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // 🆕 NEW: Navigation with map launcher
  Future<void> _navigateToHospital(Hospital hospital) async {
    try {
      // Check if any maps are available
      final availableMaps = await MapLauncher.installedMaps;
      
      if (availableMaps.isEmpty) {
        // No maps installed, show error
        _showErrorDialog(
          widget.isSinhala 
              ? 'සිතියම් යෙදුමක් හමු නොවීය' 
              : 'No map applications found'
        );
        return;
      }
      
      // If multiple maps, show selection dialog
      if (availableMaps.length > 1) {
        _showMapSelectionDialog(availableMaps, hospital);
      } else {
        // Only one map, use it directly
        await availableMaps.first.showDirections(
          destination: Coords(hospital.latitude, hospital.longitude),
          destinationTitle: hospital.name,
          directionsMode: DirectionsMode.driving,
        );
      }
    } catch (e) {
      print('Navigation error: $e');
      _showErrorDialog(
        widget.isSinhala 
            ? 'යොමු කිරීමේ දෝෂයකි' 
            : 'Navigation error'
      );
    }
  }

  //  NEW: Map selection dialog
  void _showMapSelectionDialog(List<AvailableMap> maps, Hospital hospital) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isSinhala ? 'සිතියම තෝරන්න' : 'Choose Map'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: maps.length,
            itemBuilder: (context, index) {
              final map = maps[index];
              return ListTile(
               leading: Image.memory(
                    map.icon as Uint8List, 
                    width: 30, 
                    height: 30,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.map, color: Colors.blue),
                  ),
                title: Text(map.mapName),
                onTap: () async {
                  Navigator.pop(context);
                  await map.showDirections(
                    destination: Coords(hospital.latitude, hospital.longitude),
                    destinationTitle: hospital.name,
                    directionsMode: DirectionsMode.driving,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  //  NEW: Error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isSinhala ? 'දෝෂයකි' : 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'හරි' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSinhala ? 'අසල රෝහල්' : 'Nearby Hospitals'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _findHospitals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _findHospitals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                        ),
                        child: Text(widget.isSinhala ? 'නැවත උත්සාහ කරන්න' : 'Try Again'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _hospitals.length,
                  itemBuilder: (context, index) {
                    return _buildHospitalCard(_hospitals[index], index + 1);
                  },
                ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            hospital.distanceDisplay,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          if (hospital.hasEmergency)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ER',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hospital.is24Hours)
                  Icon(Icons.access_time, color: Colors.green.shade600, size: 18),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.add_location, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hospital.address,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
            
            if (hospital.phoneNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    hospital.phoneNumber!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons - UPDATED navigation onTap
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions,
                    label: widget.isSinhala ? 'යන්න' : 'Navigate',
                    color: Colors.blue,
                    onTap: () => _navigateToHospital(hospital), // ← Changed this line
                  ),
                ),
                const SizedBox(width: 8),
                if (hospital.phoneNumber != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone,
                      label: widget.isSinhala ? 'අමතන්න' : 'Call',
                      color: Colors.green,
                      onTap: () => OpenStreetMapService.callHospital(hospital.phoneNumber!),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}