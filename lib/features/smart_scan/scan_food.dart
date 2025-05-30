import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
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
  bool _isDetecting = false;
  String? _detectedLabel;
  double? _confidence;
  bool _hasPermission = false;
  bool _isLoading = false;
  int frameCount = 0;

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

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high, // Try high, you can set medium if laggy
        enableAudio: false,
      );
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
      print('\x1B[34m[DEBUG] Camera initialized and stream started\x1B[0m');
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

  void _processCameraImage(CameraImage image) async {
    frameCount++;
    print('\x1B[34m[DEBUG] Processing frame #$frameCount\x1B[0m');
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      // 1. Concatenate image bytes from all planes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // 2. Get image size
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // 3. Ensure _cameraController is available and initialized
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        print('\x1B[34m[DEBUG] CameraController not initialized\x1B[0m');
        _isDetecting = false;
        return;
      }
      final camera = _cameraController!.description;

      // 4. Determine image rotation
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      // 5. Determine input image format
      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      // 6. Create InputImageMetadata
      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      // 7. Create InputImage
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      // 8. Initialize and use the ImageLabeler (VERY low threshold)
      final options = ImageLabelerOptions(confidenceThreshold: 0.01);
      final imageLabeler = ImageLabeler(options: options);
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

      // 9. Update UI with detected labels (if widget is still mounted)
      if (mounted) {
        if (labels.isNotEmpty) {
          print('\x1B[34m[DEBUG] Labels detected (count: ${labels.length})\x1B[0m');
          for (final label in labels) {
            print('\x1B[34mMLKit label: ${label.label} (conf: ${label.confidence})\x1B[0m');
          }
          setState(() {
            _detectedLabel = labels.first.label;
            _confidence = labels.first.confidence;
          });
        } else {
          print('\x1B[34mNo labels detected in frame #$frameCount\x1B[0m');
          setState(() {
            _detectedLabel = null;
            _confidence = null;
          });
        }
      }

      await imageLabeler.close();

    } catch (e) {
      print('\x1B[34m[DEBUG] MLKit ERROR: $e\x1B[0m');
    } finally {
      _isDetecting = false;
    }
  }

  // Permission denied dialog with fallback (GoRouter)
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
      backgroundColor:
          theme.brightness == Brightness.light ? const Color(0xfff8fafc) : const Color(0xff232526),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            print('\x1B[34m[DEBUG] Loading camera...\x1B[0m');
            return const Center(child: CircularProgressIndicator());
          }
          if (!_hasPermission) {
            return _buildNoPermissionUI(context);
          }
          if (_cameraController == null || !_cameraController!.value.isInitialized) {
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
                    border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3), width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _detectedLabel != null
                    ? "Detected: $_detectedLabel (${((_confidence ?? 0) * 100).toStringAsFixed(1)}%)"
                    : "Point your camera at fresh produce or packaged food.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              if (_detectedLabel != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text("Add to Review"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  ),
                  onPressed: () {
                    scanController.addItem(
                      ScannedItem(
                        itemName: _detectedLabel!,
                        quantity: 1,
                        unit: null,
                        source: "food_scan",
                        isReviewed: false,
                        isEdited: false,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Detected item added!')),
                    );
                    setState(() {
                      _detectedLabel = null;
                      _confidence = null;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
