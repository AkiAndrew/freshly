import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemScreen extends StatefulWidget {
  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  File? _imageFile;
  String? _result = 'Item Image';
  bool _isDetecting = false;
  List<String> _detectedItems = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Permission Denied'),
          content: Text('Camera permission is required. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK'),
            )
          ],
        ),
      );
      throw Exception("Camera permission denied");
    }
  }

  Future<void> _captureAndDetect() async {
    try {
      await _requestCameraPermission();

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
    } catch (e) {
      print('Permission error or failure: $e');
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

  Future<void> _scanBarcode() async {
    try {
      await _requestCameraPermission();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BarcodeScannerView()),
      );

      if (result != null && result is Map) {
        final String? scannedCode = result['code'];
        final File? image = result['image'];

        if (scannedCode != null) {
          if (image != null) {
            setState(() {
              _imageFile = image;
            });
          }
          _showManualEntryDialog(scannedCode, image);
        }
      }
    } catch (e) {
      print('Barcode scan failed: $e');
    }
  }

void _showManualEntryDialog(String barcode, [File? image]) {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Add Item Info'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Container(
                height: 150,
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(image, fit: BoxFit.cover),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _expiryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Estimated Expiry (Days)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final expiry = _expiryController.text.trim();

            if (name.isEmpty || expiry.isEmpty || int.tryParse(expiry) == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter valid name and expiry (number only)')),
              );
              return;
            }

            // Check for duplicate barcode
            final existing = await FirebaseFirestore.instance
                .collection('items')
                .where('barcode', isEqualTo: barcode)
                .get();

            if (existing.docs.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Item with this barcode already exists')),
              );
              return;
            }

            await FirebaseFirestore.instance.collection('items').add({
              'name': name,
              'barcode': barcode,
              'estimatedExpiry': int.parse(expiry),
              'createdAt': FieldValue.serverTimestamp(),
            });

            Navigator.of(ctx).pop();

            // ✅ Reset everything after dialog is closed
            setState(() {
              _imageFile = null;
              _result = 'Item Image';
              _detectedItems.clear();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Item saved successfully')),
            );
          },
          child: Text('Save'),
        ),
      ],
    ),
  );
}



  void _addToPantry() {
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
                  ? Center(child: Text('No item scanned', style: TextStyle(fontSize: 18)))
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
                child: Text('Add to Database', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scanBarcode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Scan Item Barcode', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/recipe');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add Recipe', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerView extends StatefulWidget {
  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  String? _lastScanned;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Barcode")),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              final Uint8List? imageBytes = capture.image;

              File? imageFile;

              if (imageBytes != null) {
                final tempDir = Directory.systemTemp;
                final filePath = '${tempDir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.jpg';
                imageFile = await File(filePath).writeAsBytes(imageBytes);
              }

              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code != _lastScanned) {
                  _lastScanned = code;
                  Navigator.pop(context, {'code': code, 'image': imageFile});
                  break;
                }
              }
            },
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
