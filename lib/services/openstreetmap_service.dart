import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String? phoneNumber;
  final String? openingHours;
  final String? website;
  final Map<String, dynamic> tags;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.phoneNumber,
    this.openingHours,
    this.website,
    this.tags = const {},
  });

  // For displaying in UI
  String get distanceDisplay => '${distance.toStringAsFixed(1)} km';
  
  // Check if hospital has emergency department
  bool get hasEmergency => tags['emergency'] == 'yes';
  
  // Check if 24/7
  bool get is24Hours => openingHours?.toLowerCase().contains('24/7') ?? false;
}

class OpenStreetMapService {
  // No API key needed! Just use OpenStreetMap's free services
  
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  // Rate limiting: 1 request per second (be nice to free service)
  static DateTime _lastRequest = DateTime.now().subtract(const Duration(seconds: 1));
  
  static Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequest);
    
    if (timeSinceLastRequest.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - timeSinceLastRequest.inMilliseconds));
    }
    _lastRequest = DateTime.now();
  }

  // Find nearby hospitals using OpenStreetMap Overpass API
  static Future<List<Hospital>> findNearbyHospitals(Position position) async {
    try {
      await _respectRateLimit();
      
      // Overpass QL query to find hospitals within 5km
      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="hospital"](around:5000,${position.latitude},${position.longitude});
          way["amenity"="hospital"](around:5000,${position.latitude},${position.longitude});
          relation["amenity"="hospital"](around:5000,${position.latitude},${position.longitude});
        );
        out body center;
      ''';
      
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: query,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'MotherlyApp/1.0 (your-email@example.com)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        List<Hospital> hospitals = [];
        
        for (var element in elements) {
          // Get coordinates (handles nodes, ways, and relations)
          double lat = 0.0;
          double lon = 0.0;
          
          if (element['type'] == 'node') {
            lat = element['lat'] ?? 0.0;
            lon = element['lon'] ?? 0.0;
          } else {
            // For ways and relations, use center point
            lat = element['center']?['lat'] ?? 0.0;
            lon = element['center']?['lon'] ?? 0.0;
          }
          
          // Skip if coordinates are invalid
          if (lat == 0.0 || lon == 0.0) continue;
          
          // Calculate distance
          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lat,
            lon,
          ) / 1000; // Convert to km
          
          // Skip if beyond 5km (API sometimes returns slightly outside)
          if (distance > 6) continue;
          
          final tags = element['tags'] ?? {};
          
          // Get name (try various common tags)
          String name = tags['name'] ?? 
                       tags['name:en'] ?? 
                       tags['official_name'] ?? 
                       tags['short_name'] ?? 
                       'Hospital';
          
          // Build address
          String address = _buildAddress(tags);
          
          // Get phone number
          String? phone = tags['phone'] ?? 
                         tags['contact:phone'] ?? 
                         tags['emergency:phone'];
          
          // Get opening hours
          String? openingHours = tags['opening_hours'] ?? 
                                 tags['opening_hours:covid19'];
          
          // Get website
          String? website = tags['website'] ?? 
                           tags['contact:website'] ?? 
                           tags['url'];
          
          hospitals.add(Hospital(
            id: '${element['type']}-${element['id']}',
            name: name,
            address: address,
            latitude: lat,
            longitude: lon,
            distance: distance,
            phoneNumber: phone,
            openingHours: openingHours,
            website: website,
            tags: tags,
          ));
        }
        
        // Remove duplicates (same hospital may appear multiple times)
        hospitals = _removeDuplicates(hospitals);
        
        // Sort by distance
        hospitals.sort((a, b) => a.distance.compareTo(b.distance));
        
        return hospitals.take(10).toList(); // Return top 10
      }
      
      return [];
    } catch (e) {
      print('Error finding hospitals: $e');
      return [];
    }
  }

  // Helper: Build address from OSM tags
  static String _buildAddress(Map<String, dynamic> tags) {
    List<String> parts = [];
    
    // Street address
    if (tags['addr:housenumber'] != null || tags['addr:street'] != null) {
      String street = '';
      if (tags['addr:housenumber'] != null) {
        street += tags['addr:housenumber'];
      }
      if (tags['addr:street'] != null) {
        if (street.isNotEmpty) street += ' ';
        street += tags['addr:street'];
      }
      if (street.isNotEmpty) parts.add(street);
    }
    
    // City/Suburb
    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    } else if (tags['addr:suburb'] != null) {
      parts.add(tags['addr:suburb']);
    }
    
    // District
    if (tags['addr:district'] != null) {
      parts.add(tags['addr:district']);
    }
    
    // Postal code
    if (tags['addr:postcode'] != null) {
      parts.add(tags['addr:postcode']);
    }
    
    // State/Province
    if (tags['addr:state'] != null) {
      parts.add(tags['addr:state']);
    }
    
    // Country
    if (tags['addr:country'] != null) {
      parts.add(tags['addr:country']);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  // Helper: Remove duplicate hospitals by name and approximate location
  static List<Hospital> _removeDuplicates(List<Hospital> hospitals) {
    final uniqueHospitals = <Hospital>[];
    final seenIds = <String>{};
    
    for (var hospital in hospitals) {
      // Create a simple key from name and rough location
      String key = '${hospital.name}_${hospital.latitude.toStringAsFixed(2)}_${hospital.longitude.toStringAsFixed(2)}';
      
      if (!seenIds.contains(key)) {
        seenIds.add(key);
        uniqueHospitals.add(hospital);
      }
    }
    
    return uniqueHospitals;
  }

  // Get additional details about a specific hospital
  static Future<Map<String, dynamic>> getHospitalDetails(String osmId) async {
    try {
      await _respectRateLimit();
      
      final url = '$_nominatimUrl/details.php?osmtype=${osmId[0]}&osmid=${osmId.substring(2)}&format=json';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MotherlyApp/1.0 (your-email@example.com)',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error getting hospital details: $e');
      return {};
    }
  }

  // Navigate to hospital (works with any maps app)
  static Future<void> navigateToHospital(Hospital hospital) async {
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${hospital.latitude},${hospital.longitude}'
        '&travelmode=driving';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Fallback to Apple Maps on iOS
      final appleUrl = 'http://maps.apple.com/?daddr=${hospital.latitude},${hospital.longitude}';
      if (await canLaunch(appleUrl)) {
        await launch(appleUrl);
      }
    }
  }

  // Make phone call
  static Future<void> callHospital(String phoneNumber) async {
    // Clean phone number
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'tel:$cleaned';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}