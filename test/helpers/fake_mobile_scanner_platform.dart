import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera platform without a camera. [scan] hands a barcode to the running
/// barcode scanner, as if the camera had seen it.
class FakeMobileScannerPlatform extends MobileScannerPlatform {
  new _();

  /// Replaces the camera platform until the current test ends.
  factory install() {
    final original = MobileScannerPlatform.instance;
    final fake = FakeMobileScannerPlatform._();
    MobileScannerPlatform.instance = fake;
    addTearDown(() async {
      MobileScannerPlatform.instance = original;
      await fake._barcodes.close();
      await fake._torchStates.close();
      await fake._zoomScales.close();
    });
    return fake;
  }

  final _barcodes = StreamController<BarcodeCapture?>.broadcast();
  final _torchStates = StreamController<TorchState>.broadcast();
  final _zoomScales = StreamController<double>.broadcast();

  var _isRunning = false;

  /// Whether a scanner runs and so sees what [scan] shows.
  bool get isRunning => _isRunning;

  /// The area the scanner reads in, as the scanner last set it.
  Rect? scanWindow;

  /// Shows the EAN-13 [barcode] to the camera, which reads it on two frames
  /// in a row, as a held barcode is.
  void scan(String barcode) {
    glimpse(barcode);
    glimpse(barcode);
  }

  /// Lets the camera read [barcode] on a single frame only, as a code that
  /// crosses the picture or a misread is.
  void glimpse(String barcode) {
    expect(isRunning, isTrue, reason: 'No scanner sees the barcode.');
    _barcodes.add(
      BarcodeCapture(
        barcodes: [Barcode(rawValue: barcode, format: BarcodeFormat.ean13)],
      ),
    );
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => _torchStates.stream;

  @override
  Stream<double> get zoomScaleStateStream => _zoomScales.stream;

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    _isRunning = true;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1080, 1920),
    );
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {
    scanWindow = window;
  }

  @override
  Future<void> dispose() async {}
}
