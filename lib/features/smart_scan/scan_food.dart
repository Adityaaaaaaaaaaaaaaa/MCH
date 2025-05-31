import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../utils/appbar.dart';
import '/models/scanned_item.dart';
import 'smart_scan_controller.dart';

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
  List<DetectedObject>? _detectedObjects;

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
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      _cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      setState(() => _isCameraReady = true);
      print('\x1B[34m[DEBUG] Camera initialized and ready\x1B[0m');
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

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() {
      _pickedImage = null;
      _detectedObjects = null;
    });
    try {
      final XFile image = await _cameraController!.takePicture();
      _pickedImage = File(image.path);
      print('\x1B[34m[DEBUG] Photo captured: ${image.path}\x1B[0m');
      await _detectObjects(_pickedImage!);
    } catch (e) {
      print('\x1B[34m[DEBUG] Error taking photo: $e\x1B[0m');
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _pickedImage = null;
      _detectedObjects = null;
    });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (pickedFile == null) {
        print('\x1B[34m[DEBUG] No gallery image picked\x1B[0m');
        return;
      }
      _pickedImage = File(pickedFile.path);
      print('\x1B[34m[DEBUG] Image picked from gallery: ${pickedFile.path}\x1B[0m');
      await _detectObjects(_pickedImage!);
    } catch (e) {
      print('\x1B[34m[DEBUG] Error picking gallery image: $e\x1B[0m');
    }
  }

  Future<void> _detectObjects(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final options = ObjectDetectorOptions(
        classifyObjects: true,
        multipleObjects: true,
        mode: DetectionMode.single,
      );
      final detector = ObjectDetector(options: options);
      final objects = await detector.processImage(inputImage);
      print('\x1B[34m[DEBUG] Detected ${objects.length} objects with bounding boxes\x1B[0m');
      for (final object in objects) {
        final label = object.labels.isNotEmpty ? object.labels.first.text : 'Unknown';
        final conf = object.labels.isNotEmpty ? object.labels.first.confidence : 0.0;
        print('\x1B[34m[DEBUG] Object: $label (${(conf * 100).toStringAsFixed(1)}%), Box: ${object.boundingBox}\x1B[0m');
      }
      setState(() => _detectedObjects = objects);
      await detector.close();
    } catch (e) {
      print('\x1B[34m[DEBUG] Object Detection ERROR: $e\x1B[0m');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImageWithBoxes() {
    if (_pickedImage == null) return const SizedBox();
    return Stack(
      children: [
        Image.file(_pickedImage!, width: 320, height: 240, fit: BoxFit.cover),
        if (_detectedObjects != null)
          ..._detectedObjects!.map((object) {
            final label = object.labels.isNotEmpty ? object.labels.first.text : 'Unknown';
            final confidence = object.labels.isNotEmpty ? object.labels.first.confidence : 0.0;
            final box = object.boundingBox;
            return Positioned(
              left: box.left * 320 / box.width,
              top: box.top * 240 / box.height,
              child: Container(
                width: box.width * 320 / box.width,
                height: box.height * 240 / box.height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      "$label (${(confidence * 100).toStringAsFixed(1)}%)",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanController = ref.read(smartScanControllerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: "Scan Food",
        showMenu: false,
        height: 90,
        borderRadius: 26,
        topPadding: 48,
      ),
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xfff8fafc)
          : const Color(0xff232526),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_isLoading) return const Center(child: CircularProgressIndicator());
          if (!_hasPermission) return _buildNoPermissionUI(context);

          if (_pickedImage != null) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 320,
                        height: 240,
                        child: _buildImageWithBoxes(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_detectedObjects != null)
                      ..._detectedObjects!.map((obj) {
                        final label = obj.labels.isNotEmpty ? obj.labels.first.text : 'Unknown';
                        final conf = obj.labels.isNotEmpty ? obj.labels.first.confidence : 0.0;
                        return Text('Detected: $label (${(conf * 100).toStringAsFixed(1)}%)',
                            style: theme.textTheme.bodyMedium);
                      }),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text("Add to Review"),
                      onPressed: () {
                        for (var obj in _detectedObjects ?? []) {
                          final label = obj.labels.isNotEmpty ? obj.labels.first.text : 'Unknown';
                          scanController.addItem(
                            ScannedItem(
                              itemName: label,
                              quantity: 1,
                              unit: null,
                              source: "food_scan",
                              isReviewed: false,
                              isEdited: false,
                            ),
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Detected items added!')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Go to Review Screen"),
                      onPressed: () {
                        print('\x1B[34m[DEBUG] Navigating to /reviewScreen\x1B[0m');
                        context.push('/reviewScreen');
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera),
                          label: const Text("Take Another Photo"),
                          onPressed: _takePicture,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Pick from Gallery"),
                          onPressed: _pickFromGallery,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          if (!_isCameraReady || _cameraController == null || !_cameraController!.value.isInitialized) {
            print('\x1B[34m[DEBUG] Waiting for camera initialization...\x1B[0m');
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Container(
                  width: 320,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text("Snap Photo"),
                    onPressed: _takePicture,
                  ),
                  const SizedBox(width: 18),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Pick from Gallery"),
                    onPressed: _pickFromGallery,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
