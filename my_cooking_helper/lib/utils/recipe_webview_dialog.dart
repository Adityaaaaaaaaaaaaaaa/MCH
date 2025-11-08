import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeWebViewDialog extends StatefulWidget {
  final String url;
  const RecipeWebViewDialog({Key? key, required this.url}) : super(key: key);

  @override
  State<RecipeWebViewDialog> createState() => _RecipeWebViewDialogState();
}

class _RecipeWebViewDialogState extends State<RecipeWebViewDialog> {
  late final WebViewController _controller;
  int _progress = 0;

  // Track SSL problems and current top-level URL
  bool _sslWarning = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (u) {
            _currentUrl = u;
            setState(() {
              _progress = 10;
              _sslWarning = false; // reset on new navigation
            });
          },
          onProgress: (p) => setState(() => _progress = p.clamp(0, 100)),
          onPageFinished: (u) {
            _currentUrl = u;
            setState(() => _progress = 100);
          },
          onWebResourceError: (err) {
            // ignore: avoid_print
            print('\x1B[34m[WEBVIEW] error: ${err.errorCode} ${err.description}\x1B[0m');

            // SSL errors in Chromium are in the -200s range (certificate problems).
            final isLikelySsl =
                (err.errorCode <= -200 && err.errorCode >= -299) ||
                err.description.toLowerCase().contains('ssl');

            if (isLikelySsl && mounted) {
              setState(() => _sslWarning = true);
              // Optional heads-up for the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Some secure connections failed. Page may be incomplete.'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      );

    // Neutral mobile UA (no device spoofing)
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };

    // Always try to open HTTPS (your upstream already prefers it)
    _controller.loadRequest(Uri.parse(_ensureHttps(widget.url)), headers: headers);
  }

  String _ensureHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  String _toHttp(String url) {
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'http://');
    } else if (!url.startsWith('http')) {
      return 'http://$url';
    }
    return url; // already http
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  Future<bool> _handleSystemBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false; // consume back, stay in dialog
    }
    return true; // close dialog
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmTryHttp() async {
    final httpUrl = _toHttp(_currentUrl.isNotEmpty ? _currentUrl : widget.url);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Try insecure HTTP?'),
        content: const Text(
          'This site had TLS/SSL issues. Loading via HTTP is insecure and could expose your data. '
          'Do you still want to try HTTP just for viewing?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try HTTP')),
        ],
      ),
    );
    if (ok == true) {
      await _controller.loadRequest(Uri.parse(httpUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              // Dim backdrop
              Positioned.fill(
                child: Container(
                  color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.20),
                ),
              ),

              // WebView card
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0E0F12) : Colors.white.withOpacity(0.99),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24.r,
                        spreadRadius: 2.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(child: WebViewWidget(controller: _controller)),

                      if (_progress < 100)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _progress == 0 ? null : (_progress / 100.0),
                            minHeight: 2.2.h,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),

                      // SSL warning banner (only when TLS issues detected)
                      if (_sslWarning)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: EdgeInsets.only(top: 10.h),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.orange.withOpacity(0.15) : Colors.orange[50],
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: isDark ? Colors.orange.withOpacity(0.35) : Colors.orange.shade200,
                              ),
                            ),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10.w,
                              children: [
                                Icon(Icons.lock_open_rounded,
                                    size: 16.sp,
                                    color: isDark ? Colors.orange[200] : Colors.orange[800]),
                                Text(
                                  'Some secure connections failed',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.orange[200] : Colors.orange[800],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _openExternally(_currentUrl.isNotEmpty ? _currentUrl : widget.url),
                                  child: Text('Open in browser', style: TextStyle(fontSize: 12.sp)),
                                ),
                                TextButton(
                                  onPressed: _confirmTryHttp,
                                  child: Text('Try HTTP', style: TextStyle(fontSize: 12.sp)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 16.h,
                right: 16.w,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(28.r),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: Icon(Icons.close_rounded, size: 26.sp, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
