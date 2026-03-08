import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motherly_v1/emergency_hospitals_screen.dart';
import 'package:motherly_v1/services/api_service.dart';
import 'package:motherly_v1/models/scan_result_model.dart';
import 'package:motherly_v1/firestore/firestore_service.dart';

class ScanScreen extends StatefulWidget {
  final bool isSinhala;
  final String infantId;

  const ScanScreen({
    super.key,
    required this.isSinhala,
    required this.infantId,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  late FirestoreService _firestoreService;
  File? _imageFile;
  bool _isAnalyzing = false;
  ScanResult? _scanResult;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = true;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    setState(() {
      _isCheckingConnection = true;
      _connectionError = null;
    });
    
    try {
      final connected = await ApiService.checkHealth();
      setState(() {
        _isBackendConnected = connected;
        _isCheckingConnection = false;
        if (!connected) {
          _connectionError = 'Could not connect to server';
        }
      });
    } catch (e) {
      setState(() {
        _isBackendConnected = false;
        _isCheckingConnection = false;
        _connectionError = e.toString();
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _scanResult = null;
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Show a dialog for cold start warning
      if (!_isBackendConnected) {
        _showColdStartDialog();
      }
      
      final result = await ApiService.analyzeBabyImage(
        _imageFile!,
        isSinhala: widget.isSinhala,
      );
      
      setState(() {
        _scanResult = result;
        _isAnalyzing = false;
        _isBackendConnected = true; // Connection confirmed working
      });
      String resultText = widget.isSinhala ? result.predictionSinhala : result.prediction;
      await _firestoreService.saveScanResult(
        infantId: widget.infantId,
        result: resultText,
      );

      // Show success message (optional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSinhala ? 'සුරකින ලදී' : 'Saved'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      if (result.requiresAttention) {
        _showEmergencySuggestion(result);
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      String errorMsg = e.toString();
      if (errorMsg.contains('timeout') || errorMsg.contains('SocketException')) {
        _showConnectionErrorDialog();
      } else {
        _showErrorDialog(errorMsg);
      }
    }
  }

  void _showColdStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(Icons.cloud_sync, color: Colors.blue, size: 40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isSinhala
                  ? 'සේවාදායකය අවදි වෙමින්...'
                  : 'Waking up server...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isSinhala
                  ? 'පළමු ඉල්ලීමට තත්පර කිහිපයක් ගතවිය හැක. කරුණාකර රැඳී සිටින්න.'
                  : 'First request may take a few seconds. Please wait.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
    
    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(Icons.wifi_off, color: Colors.red, size: 40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isSinhala
                  ? 'සේවාදායකයට සම්බන්ධ විය නොහැක'
                  : 'Cannot connect to server',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isSinhala
                  ? 'කරුණාකර ඔබගේ අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isSinhala ? 'හරි' : 'OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkBackendConnection();
              _analyzeImage();
            },
            child: Text(widget.isSinhala ? 'නැවත උත්සාහ කරන්න' : 'Retry'),
          ),
        ],
      ),
    );
  }

  void _showEmergencySuggestion(ScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(Icons.warning, color: Colors.orange, size: 40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isSinhala
                  ? 'අවධානය යොමු කළ යුතුයි'
                  : 'Attention Required',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(widget.isSinhala ? result.predictionSinhala : result.prediction),
            const SizedBox(height: 10),
            ...result.recommendations.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(r)),
                ],
              ),
            )),
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
        title: Text(widget.isSinhala ? 'ස්කෑන් පරීක්ෂාව' : 'Health Scan'),
        backgroundColor: Colors.pink.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkBackendConnection,
            tooltip: widget.isSinhala ? 'නැවත සම්බන්ධ කරන්න' : 'Reconnect',
          ),
        ],
      ),
      body: Column(
        children: [
          // Backend connection status
          if (_isCheckingConnection)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade100,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isSinhala
                          ? 'මොහොතක් රැදී සිටින්න...'
                          : 'Connecting to server...',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            )
          else if (!_isBackendConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSinhala
                              ? 'සේවාදායකය සම්බන්ධ නැත'
                              : 'Server not connected',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_connectionError != null)
                          Text(
                            _connectionError!,
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.orange.shade700),
                    onPressed: _checkBackendConnection,
                    iconSize: 20,
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Image preview
                  if (_imageFile != null) ...[
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Analyze button
                    ElevatedButton(
                      onPressed: (_isBackendConnected && !_isAnalyzing) ? _analyzeImage : null,
                      style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.pink.shade400,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isAnalyzing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Text(widget.isSinhala ? 'විශ්ලේෂණය කරමින්...' : 'Analyzing...'),
                              ],
                            )
                          : Text(widget.isSinhala ? 'විශ්ලේෂණය කරන්න' : 'Analyze Image'),
                    ),
                    
                    if (!_isBackendConnected && _imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.isSinhala
                              ? 'සේවාදායකය සම්බන්ධ වූ පසු විශ්ලේෂණය කළ හැක'
                              : 'Connect to server to analyze',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                  ],

                  // Results
                  if (_scanResult != null) ...[
  const SizedBox(height: 24),
  
  // Modern Results Card
  Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _scanResult!.requiresAttention
                    ? [Colors.red.shade400, Colors.red.shade300]
                    : [Colors.green.shade400, Colors.green.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _scanResult!.requiresAttention
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isSinhala ? 'ප්‍රතිඵලය' : 'Result',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.isSinhala
                            ? _scanResult!.predictionSinhala
                            : _scanResult!.prediction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Body content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Confidence meter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isSinhala ? 'විශ්වාසය' : 'Confidence',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _scanResult!.requiresAttention
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _scanResult!.confidencePercentage,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _scanResult!.requiresAttention
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Confidence progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _scanResult!.confidence,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _scanResult!.requiresAttention
                                ? [Colors.red.shade300, Colors.red.shade500]
                                : [Colors.green.shade300, Colors.green.shade500],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: (_scanResult!.requiresAttention
                                      ? Colors.red.shade200
                                      : Colors.green.shade200)
                                  .withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                
                const SizedBox(height: 20),
                
                // Recommendations section
                if (_scanResult!.recommendations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isSinhala ? 'යෝජනා' : 'Recommendations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ..._scanResult!.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4, right: 12),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _scanResult!.requiresAttention
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  ),
],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library,
                    label: widget.isSinhala ? 'ගැලරිය' : 'Gallery',
                    color: Colors.grey,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt,
                    label: widget.isSinhala ? 'කැමරාව' : 'Camera',
                    color: Colors.blue,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}