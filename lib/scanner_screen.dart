import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _imageFile;
  String? _result = 'No item detected yet.';
  bool _isDetecting = false;
  List<String> _detectedItems = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _captureAndDetect() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isDetecting = true;
        _result = 'Auto-detecting item...';
      });

      final labels = await _detectItems(File(pickedFile.path));

      setState(() {
        _isDetecting = false;
        _detectedItems = labels;
        _result = labels.isNotEmpty
            ? 'Detected: ${labels.join(', ')}'
            : 'No recognizable item.';
      });
    }
  }

  Future<List<String>> _detectItems(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.6),
    );
    final List<ImageLabel> labels = await labeler.processImage(inputImage);
    await labeler.close();

    return labels.map((label) => label.label).toList();
  }

  void _addToPantry() {
    // Here you would insert logic to add detected items to a central inventory list or database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_detectedItems.join(', ')} to pantry')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            
            Text('Scan Receipt'),
            Spacer(),
            Icon(Icons.settings),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile == null
                  ? Center(child: Text('Auto-detecting item', style: TextStyle(fontSize: 18)))
                  : Image.file(_imageFile!, fit: BoxFit.cover),
            ),
            SizedBox(height: 20),
            Text(
              _result ?? '',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            if (_detectedItems.isNotEmpty)
              ElevatedButton(
                onPressed: _addToPantry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Add to Pantry', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isDetecting ? null : _captureAndDetect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Capture Receipt', style: TextStyle(fontSize: 18, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}