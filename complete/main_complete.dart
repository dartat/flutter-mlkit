import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlkit_esercizio_1/barcode_detector_painter.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MLKit Esercizio 1'),
        ),
        body: const Example(),
      ),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  bool _isBusy = false;
  String _text = "";

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  CustomPaint? _customPaint;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? SizedBox(
              height: 400,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(_image!),
                  if (_customPaint != null) _customPaint!,
                  Text(_text)
                ],
              ),
            )
          : const Icon(
              Icons.image,
              size: 200,
            ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: const Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: const Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
      if (_image != null)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_path == null ? '' : 'Image path: $_path'),
        ),
    ]);
  }

  Future<Size> _calculateImageSize(path) {
    Completer<Size> completer = Completer();
    Image image = Image.file(path);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          var myImage = image.image;
          Size size = Size(myImage.width.toDouble(), myImage.height.toDouble());
          completer.complete(size);
        },
      ),
    );
    return completer.future;
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }
    setState(() {});
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setState(() {
      _image = File(path);
    });
    _path = path;

    final size = await _calculateImageSize(_image);
    final inputImage = InputImage.fromFilePath(path);
    _processImage(inputImage, size);
  }

  Future<void> _processImage(InputImage inputImage, Size size) async {
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final barcodes = await _barcodeScanner.processImage(inputImage);

    String text = 'Barcodes found: ${barcodes.length}\n\n';
    for (final barcode in barcodes) {
      text += 'Barcode: ${barcode.rawValue}\n\n';
    }
    _text = text;

    final painter = BarcodeDetectorPainter(barcodes, size, InputImageRotation.rotation0deg);
    _customPaint = CustomPaint(painter: painter);

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
