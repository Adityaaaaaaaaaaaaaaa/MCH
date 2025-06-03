import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FoodDetectionBox {
  final String label;
  final double confidence;
  final Rect boundingBox;

  FoodDetectionBox({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });
}

class Rect {
  final double left, top, right, bottom;
  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

class FoodObjectDetector {
  late Interpreter _interpreter;
  late List<String> _labels;
  final int _inputSize = 640; // Model's input size

  bool _modelLoaded = false;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/best_float32.tflite');
    final labelData = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelData.split('\n');
    _modelLoaded = true;

    // Debug: Print input and output tensor shapes
    print('\x1B[34m[DEBUG] Input tensor shape: ${_interpreter.getInputTensors()[0].shape}\x1B[0m');
    print('\x1B[34m[DEBUG] Output tensor shape: ${_interpreter.getOutputTensors()[0].shape}\x1B[0m');
  }

  bool get isLoaded => _modelLoaded;

  Future<List<FoodDetectionBox>> detectObjects(File imageFile, {double confidenceThreshold = 0.1}) async {
    if (!_modelLoaded) throw Exception('Model not loaded');

    // 1. Load and resize image
    final rawBytes = await imageFile.readAsBytes();
    img.Image? oriImage = img.decodeImage(rawBytes);
    if (oriImage == null) throw Exception('Could not decode image');
    img.Image resizedImage = img.copyResize(oriImage, width: _inputSize, height: _inputSize);

    // 2. Preprocess to input tensor (float32 normalized)
    var input = List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
      final pixel = resizedImage.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      return [
        r / 255.0,
        g / 255.0,
        b / 255.0,
      ];
    }));
    // Add batch dimension [1, H, W, 3]
    var inputTensor = [input];

    // 3. Prepare output buffer
    var outputShapes = _interpreter.getOutputTensors().map((t) => t.shape).toList();

    List<List<List<double>>> outputBuffer = List.generate(
      outputShapes[0][0], // 1 (batch)
      (_) => List.generate(
        outputShapes[0][1], // 90 (channels)
        (_) => List.filled(outputShapes[0][2], 0.0), // 8400 (positions)
      ),
    );

    // 4. Run inference
    var outputs = {0: outputBuffer};
    _interpreter.runForMultipleInputs([inputTensor], outputs);

    // --- DEBUG: Print output tensor shape ---
    print('\x1B[34m[DEBUG] OutputBuffer shape: ${outputBuffer.length} x ${outputBuffer[0].length} x ${outputBuffer[0][0].length}\x1B[0m');
    // Print the first grid cell's values for all channels (first 10)
    print('\x1B[34m[DEBUG] First grid cell values (all channels, first 10):');
    for (int c = 0; c < 10; c++) {
      print('\x1B[34m[DEBUG] Channel $c: ${outputBuffer[0][c][0]}\x1B[0m');
    }
    // Print the first channel's values for the first 10 grid positions
    print('\x1B[34m[DEBUG] First channel (all grid positions, first 10):');
    for (int pos = 0; pos < 10; pos++) {
      print('\x1B[34m[DEBUG] Position $pos: ${outputBuffer[0][0][pos]}\x1B[0m');
    }

    // 5. Parse detections (for each position, across channels)
    final results = <FoodDetectionBox>[];
    final numPositions = outputShapes[0][2]; // 8400
    final numChannels = outputShapes[0][1];  // 90
    final numClasses = numChannels - 5;      // 85

    for (int pos = 0; pos < numPositions; pos++) {
      final x = outputBuffer[0][0][pos];
      final y = outputBuffer[0][1][pos];
      final w = outputBuffer[0][2][pos];
      final h = outputBuffer[0][3][pos];
      final objectness = outputBuffer[0][4][pos];

      double maxProb = 0;
      int classIdx = 0;
      for (int c = 0; c < numClasses; c++) {
        final classProb = outputBuffer[0][5 + c][pos];
        if (classProb > maxProb) {
          maxProb = classProb;
          classIdx = c;
        }
      }
      final confidence = objectness * maxProb;
      if (confidence > confidenceThreshold) {
        // If x/y/w/h are normalized [0,1], use directly.
        // If in grid coords, divide by _inputSize to normalize:
        double left = (x - w / 2);
        double top = (y - h / 2);
        double right = (x + w / 2);
        double bottom = (y + h / 2);

        // Clamp to [0,1]
        left = left.clamp(0.0, 1.0);
        top = top.clamp(0.0, 1.0);
        right = right.clamp(0.0, 1.0);
        bottom = bottom.clamp(0.0, 1.0);

        results.add(FoodDetectionBox(
          label: _labels[classIdx],
          confidence: confidence,
          boundingBox: Rect(left: left, top: top, right: right, bottom: bottom),
        ));
      }
    }

    print('\x1B[34m[DEBUG] Boxes after confidence filter: ${results.length}\x1B[0m');
    return results;
  }
}
