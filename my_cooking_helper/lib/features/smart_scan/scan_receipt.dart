import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
import '/utils/loader.dart';
import '/utils/snackbar.dart';
import '/widgets/navigation/appbar.dart';
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
      margin: EdgeInsets.only(bottom: 10.h, top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb, color: Colors.amber, size: 22.sp),
          SizedBox(width: 8.w),
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
                size: 28.sp,
              ),
              onPressed: _toggleFlash,
              tooltip: _isFlashOn ? 'Turn off flash' : 'Turn on flash',
            ),
            SizedBox(width: 10.w),
            IconButton(
              icon: Icon(
                _isAutoFocus ? Icons.center_focus_strong : Icons.center_focus_weak,
                color: _isAutoFocus ? Colors.green : Colors.orange,
                size: 28.sp,
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
        width: enabled ? 76.w : 68.w,
        height: enabled ? 76.h : 68.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.white : Colors.grey[400]!,
            width: 7.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12.r,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            )
          ],
          color: enabled ? Colors.white : Colors.grey[200],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: enabled ? 40.w : 34.w,
            height: enabled ? 40.h : 34.h,
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
        size: 28.sp,
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
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlueAccent,
            blurRadius: 16.r,
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

  List<Widget> _buildGroupedGeminiResults(List<Map<String, dynamic>> items, ThemeData theme) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in items) {
      final String cat = (item['category'] ?? 'Uncategorized').toString().capitalize();
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    final sortedCats = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Uncategorized') return 1;
        if (b == 'Uncategorized') return -1;
        return a.compareTo(b);
      });
    return [
      for (final cat in sortedCats) ...[
        Padding(
          padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
          child: Text(
            cat,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              fontSize: 17.sp,
            ),
          ),
        ),
        ...grouped[cat]!.map((item) {
          final String name = item['itemName'] ?? item['item'] ?? '';
          final count = item['count'] ?? 1;
          return Padding(
            padding: EdgeInsets.only(left: 16.0.w, bottom: 2.h),
            child: Text(
              "$name: $count",
              style: theme.textTheme.bodyMedium,
            ),
          );
        }),
      ]
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanController = ref.read(smartScanControllerProvider.notifier);

    final PreferredSizeWidget appBarWidget = CustomAppBar(
      title: "Scan Receipt",
      showMenu: false,
      height: 90.h,
      borderRadius: 26.r,
      topPadding: 48.h,
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
                padding: EdgeInsets.only(
                  top: 20.h,
                  bottom: 20.h,
                  left: 14.w,
                  right: 14.w,
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
                      SizedBox(height: 20.h),
                      // Gemini Results
                      if (!_isLoading && _geminiResult != null && _geminiResult!.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Identified Items:",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                ..._buildGroupedGeminiResults(_geminiResult!, theme),
                              ],
                            ),
                          ),
                        )
                      else if (!_isLoading && (_geminiResult == null || _geminiResult!.isEmpty))
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0.h),
                          child: Text("No result yet.", style: theme.textTheme.labelLarge),
                        ),
                      SizedBox(height: 22.h),
                      // --- Add Items to Review Button
                      FilledButton.icon(
                        icon: Icon(Icons.check_circle_outline_rounded, size: 22.sp),
                        label: const Text("Add Item(s) to Review"),
                        onPressed: (_geminiResult == null || _geminiResult!.isEmpty)
                            ? null
                            : () {
                                int countAdded = 0;
                                for (var item in _geminiResult!) {
                                  String name = item['itemName'] ?? item['item'] ?? '';
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
                                      category: item['category'] ?? 'Uncategorized',
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                                  );
                                }
                              },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      FilledButton.icon(
                        icon: Icon(
                          Icons.reviews_outlined,
                          size: 22.sp,
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
                          padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      Text("Scan another receipt:", style: theme.textTheme.titleSmall),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.camera_enhance_outlined),
                            label: const Text("New Scan"),
                            onPressed: _retakeOrNewScan,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
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
              SizedBox(height: 120.h),
              _buildTipBanner(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _tapToFocus(details, constraints),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16.r,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22.r),
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildCameraControls(context),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
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

extension StringCapitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}