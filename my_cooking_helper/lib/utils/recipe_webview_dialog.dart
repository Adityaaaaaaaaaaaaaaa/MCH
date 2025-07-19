import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecipeWebViewDialog extends StatefulWidget {
  final String url;
  const RecipeWebViewDialog({Key? key, required this.url}) : super(key: key);

  @override
  State<RecipeWebViewDialog> createState() => _RecipeWebViewDialogState();
}

class _RecipeWebViewDialogState extends State<RecipeWebViewDialog> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.99),
            child: WebViewWidget(controller: _controller),
          ),
          Positioned(
            top: 32,
            right: 20,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 28, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
