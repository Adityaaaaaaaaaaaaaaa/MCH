import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '/utils/appbar.dart';
import '/models/item.dart';
import 'item_controller.dart';
import '/services/gemini_scanFood.dart';

class ScanFood extends ConsumerStatefulWidget {
  const ScanFood({super.key});
  @override
  ConsumerState<ScanFood> createState() => _ScanFoodState();
}

class _ScanFoodState extends ConsumerState<ScanFood> {
  CameraController? _cameraController;
  late Future<void> _initFuture;
  bool _isCameraReady = false;
  bool _isLoading = false;
  bool _hasPermission = false;
  File? _pickedImage;
  // ignore: unused_field
  Size? _imageSizeForDrawing;
  List<Map<String, dynamic>>? _geminiResult; 

  @override
  void initState() {
    super.initState();
    _initFuture = _requestPermissionAndInitCamera();
  }

  Future<void> _requestPermissionAndInitCamera() async {
    setState(() => _isLoading = true);
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _hasPermission = true;
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          print('\x1B[31m[ERROR] No cameras available\x1B[0m');
          _hasPermission = false;
          setState(() => _isLoading = false);
          return;
        }
        final camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        _cameraController = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        setState(() => _isCameraReady = true);
        print('\x1B[34m[DEBUG] Camera initialized and ready\x1B[0m');
      } catch (e) {
        print('\x1B[31m[ERROR] Failed to initialize camera: $e\x1B[0m');
        _hasPermission = false;
      }
    } else {
      _hasPermission = false;
      print('\x1B[34m[DEBUG] Camera permission denied\x1B[0m');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _retakeOrNewScan() async {
    setState(() {
      _pickedImage = null;
      _imageSizeForDrawing = null;
      _geminiResult = null;
    });
    print('\x1B[34m[DEBUG] Resetting to live camera preview\x1B[0m');
  }

  Future<void> _resetStateForNewImage() async {
    setState(() {
      _pickedImage = null;
      _imageSizeForDrawing = null;
      _geminiResult = null;
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('\x1B[31m[ERROR] Camera not ready to take picture\x1B[0m');
      return;
    }
    await _resetStateForNewImage();
    setState(() => _isLoading = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      _pickedImage = File(image.path);
      print('\x1B[34m[DEBUG] Photo captured: ${image.path}\x1B[0m');
      await _analyzeWithGemini(_pickedImage!);
    } catch (e) {
      print('\x1B[31m[ERROR] Error taking photo: $e\x1B[0m');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    await _resetStateForNewImage();
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) {
        print('\x1B[34m[DEBUG] No gallery image picked\x1B[0m');
        setState(() => _isLoading = false);
        return;
      }
      _pickedImage = File(pickedFile.path);
      print('\x1B[34m[DEBUG] Image picked from gallery: ${pickedFile.path}\x1B[0m');
      await _analyzeWithGemini(_pickedImage!);
    } catch (e) {
      print('\x1B[31m[ERROR] Error picking gallery image: $e\x1B[0m');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeWithGemini(File imageFile) async {
    setState(() {
      _geminiResult = null;
      _isLoading = true;
    });
    final geminiService = ref.read(geminiProvider);
    final result = await geminiService.analyzeFoodImage(imageFile);
    setState(() {
      _geminiResult = result;
      _isLoading = false;
    });
    print('\x1B[34m[DEBUG] Gemini result: $result\x1B[0m');
  }

  Widget _buildImageWithPreview(BuildContext context) {
    if (_pickedImage == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxWidth = screenWidth * 0.92;

    return Container(
      width: maxWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primaryColor.withOpacity(0.4), width: 1.5),
      ),
      child: Image.file(
        _pickedImage!,
        width: maxWidth,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildNoPermissionUI(BuildContext context) {
    print('\x1B[34m[DEBUG] No camera permission, showing dialog\x1B[0m');
    return Center(
      child: AlertDialog(
        title: const Text('Camera Permission Needed'),
        content: const Text(
            'Camera access is required to scan food items. Please grant permission to use this feature.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _requestPermissionAndInitCamera();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/manualInput');
            },
            child: const Text('Manual Input'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Widget _styledButton(BuildContext context, {
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isFilled = false,
  }) {
    final theme = Theme.of(context);
    final style = ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 14, 
          fontWeight: isFilled ? FontWeight.bold : FontWeight.w500
        )
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        )
      ),
    );
    if (isFilled) {
      return FilledButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
        style: style,
      );
    }
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: style.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.12);
            }
            return theme.colorScheme.secondaryContainer;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.38);
            }
            return theme.colorScheme.onSecondaryContainer;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanController = ref.read(smartScanControllerProvider.notifier);

    final PreferredSizeWidget appBarWidget = CustomAppBar(
      title: "Scan Food",
      showMenu: false,
      height: 90,
      borderRadius: 26,
      topPadding: 48,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: appBarWidget,
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xfff8fafc)
          : const Color(0xff232526),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || (_isLoading && _pickedImage == null)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_hasPermission) return _buildNoPermissionUI(context);

          // === UI when an image has been picked/captured and is ready for review ===
          if (_pickedImage != null) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: appBarWidget.preferredSize.height + MediaQuery.of(context).padding.top + 18,
                  bottom: 20, left: 14, right: 14,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                      _buildImageWithPreview(context),
                      const SizedBox(height: 18),
                      // --- Display Gemini Results
if (!_isLoading && _geminiResult != null && _geminiResult!.isNotEmpty)
  Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gemini Identified Items:",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._geminiResult!.map((item) {
            String name = item['item'] ?? '';
            double? count;
            if (item['count'] != null) {
              if (item['count'] is int) {
                count = (item['count'] as int).toDouble();
              } else if (item['count'] is double) {
                count = item['count'];
              } else if (item['count'] is String) {
                count = double.tryParse(item['count']);
              }
            }
            String display = name;
            if (count != null) {
              display += ": $count";
            }
            return Text(display, style: theme.textTheme.bodyMedium);
          }).toList(),
        ],
      ),
    ),
  )
else if (!_isLoading && (_geminiResult == null || _geminiResult!.isEmpty))
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Text("No result yet.", style: theme.textTheme.labelLarge),
  ),

                      const SizedBox(height: 22),
                      // --- Add Items to Review Button
                      _styledButton(
                        context,
                        isFilled: true,
                        icon: Icons.check_circle_outline_rounded,
                        label: "Add Item(s) to Review",
                        onPressed: (_geminiResult == null || _geminiResult!.isEmpty)
                          ? null
                          : () {
                              int count = 0;
                              for (var item in _geminiResult!) {
                                scanController.addItem(
                                  ScannedItem(
                                    itemName: item['item'],
                                    quantity: (item['count'] as num).toDouble(),
                                    unit: null,
                                    source: "gemini_vision",
                                    isReviewed: false,
                                    isEdited: false,
                                  ),
                                );
                                count++;
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$count item(s) added to review!')),
                                );
                              }
                            },
                      ),
                      const SizedBox(height: 10),
                      _styledButton(
                        context,
                        icon: Icons.reviews_outlined,
                        label: "Go to Review Screen",
                        onPressed: () {
                          print('\x1B[34m[DEBUG] Navigating to /reviewScreen\x1B[0m');
                          context.push('/reviewScreen');
                        },
                      ),
                      const SizedBox(height: 22),
                      Text("Scan another item:", style: theme.textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _styledButton(
                            context,
                            onPressed: _retakeOrNewScan,
                            icon: Icons.camera_enhance_outlined,
                            label: "New Scan",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // === UI for Live Camera Preview ===
          if (!_isCameraReady || _cameraController == null || !_cameraController!.value.isInitialized) {
            print('\x1B[34m[DEBUG] Camera not ready, showing loader or error if any.\x1B[0m');
            return const Center(child: Text("Camera not available."));
          }

          return Column(
            children: [
              SizedBox(height: appBarWidget.preferredSize.height + MediaQuery.of(context).padding.top + 8),
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _styledButton(context, onPressed: _takePicture, icon: Icons.camera_alt_rounded, label: "Snap Photo", isFilled: true),
                    _styledButton(context, onPressed: _pickFromGallery, icon: Icons.photo_library_rounded, label: "From Gallery"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
