import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/loader.dart';
import '/utils/snackbar.dart';
import '/utils/colors.dart';
import '/utils/lottie_animation.dart';
import '/widgets/camera_commons.dart';
import '/widgets/navigation/appbar.dart';
import '/models/item.dart';
import '/services/gemini_scanFood.dart';
import 'item_controller.dart';

class ScanFood extends ConsumerStatefulWidget {
  const ScanFood({super.key});
  @override
  ConsumerState<ScanFood> createState() => _ScanFoodState();
}

class _ScanFoodState extends ConsumerState<ScanFood> with TickerProviderStateMixin {
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

  final lottieController = LottieAnimationController();

  final List<String> _scanTips = [
    "Tip: Good lighting helps recognize food better!",
    "Tip: Try to capture the food from above.",
    "Tip: Keep the camera steady for a clearer scan.",
    "Tip: Avoid blurry images for best results.",
    "Tip: Remove packaging for more accurate recognition.",
    "Tip: Try one food item at a time for better scanning.",
    "Tip: Tap to focus for sharper results.",
  ];

  String get _randomTip {
    int idx = DateTime.now().millisecond % _scanTips.length;
    if (idx == _lastTipIdx) idx = (idx + 1) % _scanTips.length;
    _lastTipIdx = idx;
    return _scanTips[idx];
  }

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _isLoading = true);
    final result = await requestPermissionAndInitCamera(
      setLoading: (val) => setState(() => _isLoading = val),
      setCameraReady: (val) => setState(() => _isCameraReady = val),
      setHasPermission: (val) => setState(() => _hasPermission = val),
      setCameraController: (ctrl) => setState(() => _cameraController = ctrl),
    );
    // Result is a map: { 'controller': ..., 'isReady': ..., 'hasPerm': ... }
    setState(() {
      _cameraController = result['controller'];
      _isCameraReady = result['isReady'] ?? false;
      _hasPermission = result['hasPerm'] ?? false;
      _isLoading = false;
    });
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
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      _pickedImage = File(image.path);
      print('\x1B[34m[DEBUG] Photo captured: ${image.path}\x1B[0m');
      await _analyzeWithGemini(_pickedImage!);
    } catch (e) {
      print('\x1B[34m[DEBUG] Error taking photo: $e\x1B[0m');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    await _resetStateForNewImage();
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) {
        print('\x1B[34m[DEBUG] No gallery image picked\x1B[0m');
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      _pickedImage = File(pickedFile.path);
      print('\x1B[34m[DEBUG] Image picked from gallery: ${pickedFile.path}\x1B[0m');
      await _analyzeWithGemini(_pickedImage!);
    } catch (e) {
      print('\x1B[34m[DEBUG] Error picking gallery image: $e\x1B[0m');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeWithGemini(File imageFile) async {
    lottieController.show(
      context: context,
      assetPath: 'assets/animations/Animation_scanFood.json',
      backgroundColor: bgColor(context),
      repeat: true,
      barrierDismissible: false,
    );
    setState(() {
      _geminiResult = null;
      _isLoading = true;
    });
    final geminiService = ref.read(geminiProvider);
    final result = await geminiService.analyzeFoodImage(imageFile);
    if (!mounted) return;
    setState(() {
      _geminiResult = result;
      _isLoading = false;
    });
    print('\x1B[34m[DEBUG] Gemini result: $result\x1B[0m');
    lottieController.hide();
  }

  List<Widget> _buildGroupedGeminiResults(List<Map<String, dynamic>> items, ThemeData theme) {
    // Group items by category (default to 'Uncategorized')
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in items) {
      final String cat = (item['category'] ?? 'Uncategorized').toString().capitalize();
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    // Sort categories: "Uncategorized" always last
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
      title: "Scan Food",
      showMenu: false,
      height: 70.h,
      borderRadius: 26.r,
      topPadding:40.h,
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
            return Center(child: 
              loader(
                Colors.tealAccent,
                70,
                5,
                10,
                500,
            ));
          }
          if (!_hasPermission) return buildNoPermissionUI(context, 'food items', _requestPermissionAndInitCamera);

          // --- If image has been picked/captured
          if (_pickedImage != null) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only( top: 20.h, bottom: 20.h, left: 15.w, right: 15.w ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [ 
                            buildImageWithPreview(context: context, pickedImage: _pickedImage) 
                          ],
                        ),
                        SizedBox(height: 20.h),
                      // --- Gemini Results
                      if (!_isLoading && _geminiResult != null && _geminiResult!.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          margin:  EdgeInsets.symmetric(vertical: 10.h),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Identified Items:",
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 20.sp),
                                ),
                                SizedBox(height: 5.h),
                                ..._buildGroupedGeminiResults(_geminiResult!, theme),
                              ],
                            ),
                          ),
                        )
                      else if (!_isLoading && (_geminiResult == null || _geminiResult!.isEmpty))
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          child: Text("No result yet.", style: theme.textTheme.labelLarge),
                        ),
                      SizedBox(height: 22.h),

                      // --- ACTION BUTTONS LOGIC ---
                      if (_isLoading)
                        // While loading, only show "Try Manual Input"
                        FilledButton.icon(
                          icon: Icon(Icons.edit_note_rounded, size: 22.sp),
                          label: Text(
                            "Try Manual Input",
                            style: theme.textTheme.labelLarge,
                          ),
                          onPressed: () {
                            context.push('/manualInput');
                          },
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h)),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                        )
                      else ...[
                        // When NOT loading, show all the review/new scan buttons (unchanged)
                        FilledButton.icon(
                          icon: Icon(Icons.check_circle_outline_rounded, size: 22.sp),
                          label: const Text("Add Item(s) to Review"),
                          onPressed: (_geminiResult == null || _geminiResult!.isEmpty)
                              ? null
                              : () {
                                  int count = 0;
                                  for (var item in _geminiResult!) {
                                    scanController.addItem(
                                      ScannedItem(
                                        itemName: item['itemName'] ?? item['item'] ?? '',
                                        quantity: (item['count'] as num?)?.toDouble() ?? 1.0,
                                        unit: null,
                                        source: "gemini_vision",
                                        category: item['category'] ?? 'Uncategorized', 
                                        isReviewed: false,
                                        isEdited: false,
                                      ),
                                    );
                                    count++;
                                  }
                                  if (mounted) {
                                    SnackbarUtils.show(
                                      context, 
                                      "$count item(s) added to review!",
                                      duration: 1500, 
                                      behavior: SnackBarBehavior.floating,
                                      icon: Icons.add,
                                      iconColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.w900
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                                      backgroundColor: Colors.grey,
                                      width: 250.w,
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
                            size: 20.sp,
                            color: textColor(context),
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
                            padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h)),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                        ),
                        SizedBox(height: 25.h),
                        Text("Scan another item:", style: theme.textTheme.titleSmall),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(Icons.camera_enhance_rounded, size: 20.sp),
                              label: const Text("New Scan"),
                              onPressed: _retakeOrNewScan,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.r),
                              ),
                            ),
                          ],
                        )
                      ],
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
              buildTipBanner(context, _randomTip), //tips above
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
              buildCameraControls( //flash and focus under live preview
                context: context,
                isFlashOn: _isFlashOn,
                isAutoFocus: _isAutoFocus,
                onToggleFlash: () async {
                  await toggleFlash(
                    controller: _cameraController!,
                    isFlashOn: !_isFlashOn,
                    setFlashState: (val) => setState(() => _isFlashOn = val),
                  );
                },
                onToggleFocusMode: _toggleFocusMode,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 30.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildGalleryButton(context, _pickFromGallery),
                    buildShutterButton(onTap: _takePicture, enabled: !_isLoading),
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
