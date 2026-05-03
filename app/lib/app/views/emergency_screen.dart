import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/app_colors.dart';
import '../models/emergency_model.dart';
import '../providers/emergency_view_model.dart';
import '../widgets/custom_app_bar.dart';
import 'emergency_detail_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _affectedPatientIdController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _locationController;

  final List<String> _selectedServiceTypes = ['ambulance'];
  final List<String> _serviceTypes = [
    'ambulance',
    'police',
    'fire',
    'medical-support',
    'other',
  ];

  bool _isScanning = false;
  final MobileScannerController _scannerController = MobileScannerController();

  // Speech-to-text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _affectedPatientIdController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _locationController = TextEditingController(text: 'Fetching location...');
    _getCurrentLocation();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Speech recognition not available on this device',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _descriptionController.text = result.recognizedWords;
              _descriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _descriptionController.text.length),
              );
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_IN',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        setState(() => _locationController.text = 'Location services disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          setState(
            () => _locationController.text = 'Location permission denied',
          );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        setState(
          () => _locationController.text = 'Location permission denied forever',
        );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
          _locationController.text = 'Current Location Captured';
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _locationController.text = 'Failed to get location');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _affectedPatientIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationController.dispose();
    _scannerController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Emergency',
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppColors.background,
      body: Consumer<EmergencyViewModel>(
        builder: (context, viewModel, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Code Scanner Section
                Container(
                  height: 250,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _isScanning
                      ? Stack(
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                if (barcodes.isNotEmpty &&
                                    barcodes.first.rawValue != null) {
                                  setState(() {
                                    _affectedPatientIdController.text =
                                        barcodes.first.rawValue!;
                                    _isScanning = false;
                                  });
                                  _scannerController.stop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Patient ID Scanned Successfully',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isScanning = false;
                                  });
                                  _scannerController.stop();
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 80,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Scan QR Code to get Patient ID',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isScanning = true;
                                });
                                _scannerController.start();
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Scan QR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Affected Patient ID (from QR or manual)
                Text(
                  'Affected Patient ID',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _affectedPatientIdController,
                  decoration: InputDecoration(
                    hintText: 'Enter or scan patient ID',
                    hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),

                // Types of Emergency
                Text(
                  'Types of Emergency (Select multiple)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _serviceTypes.map((type) {
                    final isSelected = _selectedServiceTypes.contains(type);
                    return FilterChip(
                      label: Text(
                        type.replaceAll('-', ' ').toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServiceTypes.add(type);
                          } else {
                            if (_selectedServiceTypes.length > 1) {
                              _selectedServiceTypes.remove(type);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'At least one service type is required',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe the emergency situation',
                    hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isListening
                            ? const Icon(
                                Icons.mic,
                                key: ValueKey('mic_on'),
                                color: Colors.red,
                              )
                            : const Icon(
                                Icons.mic_none,
                                key: ValueKey('mic_off'),
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),

                // Location
                Text(
                  'Location',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Pre-filled Location',
                    hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textLight),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitudeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Latitude',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.textLight,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _longitudeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Longitude',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.textLight,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _triggerEmergency(context, viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: viewModel.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              )
                            : Text(
                                'Send SOS',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _triggerEmergency(
    BuildContext context,
    EmergencyViewModel viewModel,
  ) async {
    if (_affectedPatientIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter or scan patient ID',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please describe the emergency',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    final success = await viewModel.triggerEmergencySos(
      affectedPatientId: _affectedPatientIdController.text,
      latitude: _latitudeController.text,
      longitude: _longitudeController.text,
      serviceTypes: _selectedServiceTypes,
      description: _descriptionController.text,
    );

    if (success && mounted && viewModel.currentEmergency != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmergencyDetailScreen(sosId: viewModel.currentEmergency!.sosId),
        ),
      );
    }
  }
}
