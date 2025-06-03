import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '/utils/appbar.dart';
import '/models/scanned_item.dart';
import 'smart_scan_controller.dart';
// === Added for FoodObjectDetector ===
import '../services/food_object_detector.dart';

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
  Size? _imageSizeForDrawing;

  // === YOLO/Food Detector Additions ===
  FoodObjectDetector? _foodDetector;
  bool _isFoodDetectorReady = false;
  List<FoodDetectionBox>? _foodDetections;

  final double _confidenceThreshold = 0.40;

  @override
  void initState() {
    super.initState();
    _initFuture = _requestPermissionAndInitCamera();
    _loadFoodObjectDetector(); // NEW: Load YOLO model
  }

  Future<void> _loadFoodObjectDetector() async {
    _foodDetector = FoodObjectDetector();
    await _foodDetector!.loadModel();
    setState(() => _isFoodDetectorReady = true);
    print('\x1B[34m[DEBUG] FoodObjectDetector (YOLOv11s) loaded\x1B[0m');
  }

  Future<void> _requestPermissionAndInitCamera() async {
    setState(() => _isLoading = true);
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _hasPermission = true;
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          print('\x1B[34m[DEBUG] No cameras available\x1B[0m');
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
        print('\x1B[34m[DEBUG] Failed to initialize camera: $e\x1B[0m');
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
      _foodDetections = null;
      _imageSizeForDrawing = null;
    });
    print('\x1B[34m[DEBUG] Resetting to live camera preview\x1B[0m');
  }

  Future<void> _resetStateForNewImage() async {
    setState(() {
      _pickedImage = null;
      _foodDetections = null;
      _imageSizeForDrawing = null;
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('\x1B[34m[DEBUG] Camera not ready to take picture\x1B[0m');
      return;
    }
    await _resetStateForNewImage();
    setState(() => _isLoading = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      _pickedImage = File(image.path);
      print('\x1B[34m[DEBUG] Photo captured: ${image.path}\x1B[0m');
      await _detectFoodObjects(_pickedImage!);
    } catch (e) {
      print('\x1B[34m[DEBUG] Error taking photo: $e\x1B[0m');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    await _resetStateForNewImage();
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (pickedFile == null) {
        print('\x1B[34m[DEBUG] No gallery image picked\x1B[0m');
        setState(() => _isLoading = false);
        return;
      }
      _pickedImage = File(pickedFile.path);
      print('\x1B[34m[DEBUG] Image picked from gallery: ${pickedFile.path}\x1B[0m');
      await _detectFoodObjects(_pickedImage!);
    } catch (e) {
      print('\x1B[34m[DEBUG] Error picking gallery image: $e\x1B[0m');
      setState(() => _isLoading = false);
    }
  }

  // === MAIN YOLO DETECTION FUNCTION ===
  Future<void> _detectFoodObjects(File imageFile) async {
    if (!_isFoodDetectorReady) {
      print('\x1B[34m[DEBUG] FoodObjectDetector not ready\x1B[0m');
      setState(() => _isLoading = false);
      return;
    }
    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      _imageSizeForDrawing = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      final results = await _foodDetector!.detectObjects(imageFile, confidenceThreshold: _confidenceThreshold);
      print('\x1B[34m[DEBUG] Detected ${results.length} food objects\x1B[0m');
      for (final obj in results) {
        print('\x1B[34m[DEBUG] ${obj.label}: ${(obj.confidence * 100).toStringAsFixed(1)}% '
            'Box: (${obj.boundingBox.left}, ${obj.boundingBox.top}, ${obj.boundingBox.right}, ${obj.boundingBox.bottom})\x1B[0m');
      }
      setState(() => _foodDetections = results);
    } catch (e) {
      print('\x1B[34m[DEBUG] FoodObjectDetector error: $e\x1B[0m');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImageWithBoxes(BuildContext context) {
    if (_pickedImage == null || _imageSizeForDrawing == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxWidth = screenWidth * 0.92;
    final double imageW = _imageSizeForDrawing!.width;
    final double imageH = _imageSizeForDrawing!.height;
    final double imageAspect = imageW / imageH;

    double displayW = maxWidth;
    double displayH = displayW / imageAspect;
    final double maxDisplayH = MediaQuery.of(context).size.height * 0.45;
    if (displayH > maxDisplayH) {
      displayH = maxDisplayH;
      displayW = displayH * imageAspect;
    }

    return Container(
      width: displayW,
      height: displayH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primaryColor.withOpacity(0.4), width: 1.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _pickedImage!,
            width: displayW,
            height: displayH,
            fit: BoxFit.contain,
          ),
          if (_foodDetections != null)
            ..._foodDetections!.map((object) {
              // Convert normalized box to display coords
              final left = object.boundingBox.left * displayW;
              final top = object.boundingBox.top * displayH;
              final width = (object.boundingBox.right - object.boundingBox.left) * displayW;
              final height = (object.boundingBox.bottom - object.boundingBox.top) * displayH;

              final String label = object.label;
              final double confidence = object.confidence;

              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: Colors.redAccent.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        "$label (${(confidence * 100).toStringAsFixed(0)}%)",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
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
              context.go('/manualInput');
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
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      textStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 14, fontWeight: isFilled ? FontWeight.bold : FontWeight.w500)),
      shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.12);
            }
            return theme.colorScheme.secondaryContainer;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
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
                      _buildImageWithBoxes(context),
                      const SizedBox(height: 18),
                      if (!_isLoading && _foodDetections != null && _foodDetections!.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Detected Items:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ..._foodDetections!.map((obj) {
                                  final label = obj.label;
                                  final conf = obj.confidence;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Text(
                                      '• $label (${(conf * 100).toStringAsFixed(0)}%)'
                                      '${conf < _confidenceThreshold ? " - Low Confidence" : ""}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: (conf < _confidenceThreshold)
                                            ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                                            : theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        )
                      else if (!_isLoading && _foodDetections != null && _foodDetections!.isEmpty)
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 16.0),
                           child: Text("No objects detected in the image.", style: theme.textTheme.labelLarge),
                         ),
                      const SizedBox(height: 22),
                      _styledButton(
                        context,
                        isFilled: true,
                        icon: Icons.check_circle_outline_rounded,
                        label: "Add High Confidence Items",
                        onPressed: (_foodDetections == null || _foodDetections!.where((obj) => obj.confidence >= _confidenceThreshold).isEmpty)
                          ? null
                          : () {
                          int count = 0;
                          for (var obj in _foodDetections!) {
                            if (obj.confidence >= _confidenceThreshold) {
                              final label = obj.label;
                              scanController.addItem(
                                ScannedItem(itemName: label, quantity: 1, unit: null, source: "food_scan_object", isReviewed: false, isEdited: false),
                              );
                              count++;
                            }
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
