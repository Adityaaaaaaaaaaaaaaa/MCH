import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<Map<String, dynamic>> requestPermissionAndInitCamera({
  required Function(bool isLoading) setLoading,
  required Function(bool isCameraReady) setCameraReady,
  required Function(bool hasPermission) setHasPermission,
  required Function(CameraController?) setCameraController,
  ResolutionPreset resolution = ResolutionPreset.medium,
}) async {
  setLoading(true);
  final status = await Permission.camera.request();
  bool isReady = false;
  bool hasPerm = false;
  CameraController? controller;
  if (status.isGranted) {
    hasPerm = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setHasPermission(false);
        setLoading(false);
        return {};
      }
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      setCameraController(controller);
      isReady = true;
    } catch (e) {
      setHasPermission(false);
    }
  } else {
    setHasPermission(false);
  }
  setCameraReady(isReady);
  setLoading(false);
  return {
    'controller': controller,
    'isReady': isReady,
    'hasPerm': hasPerm,
  };
}

Future<void> toggleFlash({
  required CameraController controller,
  required bool isFlashOn,
  required Function(bool) setFlashState,
}) async {
  try {
    await controller.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
    setFlashState(isFlashOn);
  } catch (e) {
    print('\x1B[34m[DEBUG] Toggling flash: $e\x1B[0m');
  }
}

Future<void> toggleFocusMode({
  required CameraController controller,
  required bool isAutoFocus,
  required Function(bool) setFocusState,
}) async {
  try {
    await controller.setFocusMode(
        isAutoFocus ? FocusMode.auto : FocusMode.locked,
    );
    setFocusState(isAutoFocus);
  } catch (e) {
    print('\x1B[34m[DEBUG] Toggling focus mode: $e\x1B[0m');
  }
}

Future<void> tapToFocus({
  required CameraController controller,
  required TapDownDetails details,
  required BoxConstraints constraints,
}) async {
  if (!controller.value.isInitialized) return;
  final offset = Offset(
    details.localPosition.dx / constraints.maxWidth,
    details.localPosition.dy / constraints.maxHeight,
  );
  try {
    await controller.setFocusPoint(offset);
  } catch (e) {
    print('\x1B[34m[DEBUG] Failed to set focus point: $e\x1B[0m');
  }
}

void retakeOrNewScan({
  required Function(File?) setPickedImage,
  required Function(Size?) setImageSizeForDrawing,
  required Function(List<Map<String, dynamic>>?) setGeminiResult,
}) {
  setPickedImage(null);
  setImageSizeForDrawing(null);
  setGeminiResult(null);
}

void resetStateForNewImage({
  required Function(File?) setPickedImage,
  required Function(Size?) setImageSizeForDrawing,
  required Function(List<Map<String, dynamic>>?) setGeminiResult,
}) {
  setPickedImage(null);
  setImageSizeForDrawing(null);
  setGeminiResult(null);
}

// widget for tips banner
Widget buildTipBanner(BuildContext context, String tip, {double borderRadius = 20.0}) {
  return Container(
    margin: EdgeInsets.only(bottom: 20.h, top: 20.h),
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
    decoration: BoxDecoration(
      color: Colors.blueGrey.shade200,
      borderRadius: BorderRadius.circular(borderRadius.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lightbulb, color: Colors.amber.shade300, size: 20.sp),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            tip,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildCameraControls({
  required BuildContext context,
  required bool isFlashOn,
  required bool isAutoFocus,
  required VoidCallback onToggleFlash,
  required VoidCallback onToggleFocusMode,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: isFlashOn ? Colors.green : Colors.orange,
              size: 30.sp,
            ),
            onPressed: onToggleFlash,
            tooltip: isFlashOn ? 'Turn off flash' : 'Turn on flash',
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: Icon(
              isAutoFocus ? Icons.center_focus_strong : Icons.center_focus_weak,
              color: isAutoFocus ? Colors.green : Colors.orange,
              size: 30.sp,
            ),
            onPressed: onToggleFocusMode,
            tooltip: isAutoFocus ? 'Auto Focus' : 'Focus Locked',
          ),
        ],
      ),
    ],
  );
}

Widget buildShutterButton({
  required VoidCallback onTap,
  bool enabled = true,
}) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: enabled ? 70.w : 55.w,
      height: enabled ? 70.h : 55.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: enabled ? Colors.white : Colors.grey[400]!,
          width: 7.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.r,
            spreadRadius: 3,
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

Widget buildGalleryButton(BuildContext context, VoidCallback onPressed) {
  return FloatingActionButton(
    heroTag: 'galleryBtn',
    backgroundColor: Colors.white,
    elevation: 4,
    mini: false,
    onPressed: onPressed,
    tooltip: "Select from Gallery",
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Icon(
        Icons.photo_library_rounded,
        color: Theme.of(context).primaryColor,
        size: 30.sp,
      ),
    ),
  );
}

Widget buildImageWithPreview({
  required BuildContext context,
  required File? pickedImage,
}) {
  if (pickedImage == null) return const SizedBox.shrink();
  final double screenWidth = MediaQuery.of(context).size.width;
  final double maxWidth = screenWidth * 0.92;
  return Container(
    width: maxWidth.w,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.r),
      border: Border.all(width: 1.5.w),
      boxShadow: [
        BoxShadow(
          color: Colors.lightBlueAccent,
          blurRadius: 20.r,
          offset: Offset(1, 1),
        ),
      ]
    ),
    child: Image.file(
      pickedImage,
      width: maxWidth,
      fit: BoxFit.contain,
    ),
  );
}

// no-permission UI
Widget buildNoPermissionUI(
  BuildContext context,
  String featureName,
  Future<void> Function() onTryAgain,
) {
  return Center(
    child: AlertDialog(
      title: const Text('Camera Permission Needed'),
      content: Text('Camera access is required to scan $featureName. Please grant permission to use this feature.'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await onTryAgain();
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
