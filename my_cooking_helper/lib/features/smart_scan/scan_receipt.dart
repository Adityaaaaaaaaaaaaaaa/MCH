import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '/utils/colors.dart';
import '/utils/loader.dart';
import '/utils/snackbar.dart';
import '/utils/appbar.dart';
import '/models/item.dart';
import 'item_controller.dart';
import '/services/gemini_scanReceipt.dart'; 

class ScanReceipt extends ConsumerStatefulWidget {
  const ScanReceipt({super.key});
  @override
  ConsumerState<ScanReceipt> createState() => _ScanReceiptState();
}

class _ScanReceiptState extends ConsumerState<ScanReceipt> {
  CameraController? _cameraController;
  late Future<void> _initFuture;
  bool _isCameraReady = false;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isFlashOn = false;
  bool _isAutoFocus = true;
  File? _pickedImage;
  // ignore: unused_field
  Size? _imageSizeForDrawing;
  List<Map<String, dynamic>>? _geminiResult;
  int _lastTipIdx = -1;

  final List<String> _scanTips = [
    "Tip: Capture the receipt under good lighting!",
    "Tip: Flatten the receipt for better results.",
    "Tip: Ensure the entire receipt fits in the frame.",
    "Tip: Remove any covers or folds from the receipt.",
    "Tip: Tap to focus on the receipt for sharpness.",
    "Tip: Avoid glare for the best scan.",
  ];

  String get _randomTip {
    int idx = DateTime.now().millisecondsSinceEpoch % _scanTips.length;
    if (idx == _lastTipIdx) idx = (idx + 1) % _scanTips.length;
    _lastTipIdx = idx;
    return _scanTips[idx];
  }

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
          ResolutionPreset.medium,
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

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
      print('\x1B[34m[DEBUG] Flash toggled: $_isFlashOn\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG] Toggling flash: $e\x1B[0m');
    }
  }

  Future<void> _toggleFocusMode() async {
    if (_cameraController == null) return;
    try {
      _isAutoFocus = !_isAutoFocus;
      await _cameraController!.setFocusMode(
        _isAutoFocus ? FocusMode.auto : FocusMode.locked,
      );
      setState(() {});
      print('\x1B[34m[DEBUG] Focus mode toggled: ${_isAutoFocus ? "Auto" : "Locked"}\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG] Toggling focus mode: $e\x1B[0m');
    }
  }

  Future<void> _tapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    try {
      await _cameraController!.setFocusPoint(offset);
      print('\x1B[34m[DEBUG] Focus set at: $offset\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG] Failed to set focus point: $e\x1B[0m');
    }
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
      print('\x1B[34m[DEBUG] Camera not ready to take picture\x1B[0m');
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
      print('\x1B[34m[DEBUG] Error taking photo: $e\x1B[0m');
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
      print('\x1B[34m[DEBUG] Error picking gallery image: $e\x1B[0m');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeWithGemini(File imageFile) async {
    setState(() {
      _geminiResult = null;
      _isLoading = true;
    });
    final geminiReceiptService = ref.read(geminiReceiptProvider);
    final result = await geminiReceiptService.analyzeReceiptImage(imageFile); // result is now List<Map<String, dynamic>>
    try {
      setState(() {
        _geminiResult = result;
        _isLoading = false;
      });
      print('\x1B[34m[DEBUG] Gemini receipt result: $result\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG] Failed to extract items from response: $e\x1B[0m');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTipBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _randomTip,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isFlashOn ? Colors.green : Colors.orange,
                size: 28,
              ),
              onPressed: _toggleFlash,
              tooltip: _isFlashOn ? 'Turn off flash' : 'Turn on flash',
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                _isAutoFocus ? Icons.center_focus_strong : Icons.center_focus_weak,
                color: _isAutoFocus ? Colors.green : Colors.orange,
                size: 28,
              ),
              onPressed: _toggleFocusMode,
              tooltip: _isAutoFocus ? 'Auto Focus' : 'Focus Locked',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShutterButton({required VoidCallback onTap, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: enabled ? 76 : 68,
        height: enabled ? 76 : 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.white : Colors.grey[400]!,
            width: 7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            )
          ],
          color: enabled ? Colors.white : Colors.grey[200],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: enabled ? 40 : 34,
            height: enabled ? 40 : 34,
            decoration: BoxDecoration(
              color: enabled ? Colors.redAccent : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'galleryBtn',
      backgroundColor: Colors.white,
      elevation: 4,
      mini: true,
      onPressed: _pickFromGallery,
      tooltip: "Select from Gallery",
      child: Icon(
        Icons.photo_library_rounded,
        color: Theme.of(context).primaryColor,
        size: 28,
      ),
    );
  }

  Widget _buildImageWithPreview(BuildContext context) {
    if (_pickedImage == null) return const SizedBox.shrink();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxWidth = screenWidth * 0.92;
    return Container(
      width: maxWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.lightBlueAccent,
            blurRadius: 16,
            offset: Offset(1, 1),
          ),
        ],
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
            'Camera access is required to scan receipts. Please grant permission to use this feature.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanController = ref.read(smartScanControllerProvider.notifier);

    final PreferredSizeWidget appBarWidget = CustomAppBar(
      title: "Scan Receipt",
      showMenu: false,
      height: 90,
      borderRadius: 26,
      topPadding: 48,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: appBarWidget,
      backgroundColor: bgColor(context),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || (_isLoading && _pickedImage == null)) {
            return Center(
              child: loader(
                Colors.lightGreen,
                70,
                5,
                10,
                500,
              ),
            );
          }
          if (!_hasPermission) return _buildNoPermissionUI(context);

          if (_pickedImage != null) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                  left: 14,
                  right: 14,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildImageWithPreview(context),
                        if (_isLoading)
                          Container(
                            color: Colors.transparent,
                            child: Center(
                              child: loader(
                                Colors.lightBlueAccent,
                                70,
                                5,
                                10,
                                500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // --- Gemini Results
                      if (!_isLoading && _geminiResult != null && _geminiResult!.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Identified Items:",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
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
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                        label: const Text("Add Item(s) to Review"),
                        onPressed: (_geminiResult == null || _geminiResult!.isEmpty)
                            ? null
                            : () {
                                int countAdded = 0;
                                for (var item in _geminiResult!) {
                                  String name = item['item'] ?? '';
                                  double quantity = 1.0;
                                  if (item['count'] != null) {
                                    if (item['count'] is int) {
                                      quantity = (item['count'] as int).toDouble();
                                    } else if (item['count'] is double) {
                                      quantity = item['count'];
                                    } else if (item['count'] is String) {
                                      final parsed = double.tryParse(item['count']);
                                      if (parsed != null) quantity = parsed;
                                    }
                                  }
                                  scanController.addItem(
                                    ScannedItem(
                                      itemName: name,
                                      quantity: quantity,
                                      unit: null,
                                      source: "gemini_receipt",
                                      isReviewed: false,
                                      isEdited: false,
                                    ),
                                  );
                                  countAdded++;
                                }
                                if (mounted) {
                                  SnackbarUtils.show(
                                    context,
                                    "$countAdded item(s) added to review!",
                                    duration: 1500,
                                    behavior: SnackBarBehavior.floating,
                                    icon: Icons.add,
                                    iconColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  );
                                }
                              },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        icon: Icon(
                          Icons.reviews_outlined,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          "Go to Review Screen",
                          style: theme.textTheme.labelMedium,
                        ),
                        onPressed: () {
                          print('\x1B[34m[DEBUG] Navigating to /reviewScreen\x1B[0m');
                          context.push('/reviewScreen');
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(theme.colorScheme.secondaryContainer),
                          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSecondaryContainer),
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text("Scan another receipt:", style: theme.textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_enhance_outlined),
                            label: const Text("New Scan"),
                            onPressed: _retakeOrNewScan,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // --- Camera Live Preview UI
          if (!_isCameraReady || _cameraController == null || !_cameraController!.value.isInitialized) {
            print('\x1B[34m[DEBUG] Camera not ready, showing loader or error if any.\x1B[0m');
            return const Center(child: Text("Camera not available."));
          }

          return Column(
            children: [
              const SizedBox(height: 120),
              _buildTipBanner(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _tapToFocus(details, constraints),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildCameraControls(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGalleryButton(context),
                    _buildShutterButton(
                      onTap: _isLoading ? () {} : _takePicture,
                      enabled: !_isLoading,
                    ),
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