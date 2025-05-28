import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Permission Denied'),
              content: Text(
                'Camera permission is required. Please enable it in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('OK'),
                ),
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
          _result =
              labels.isNotEmpty
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

          final snapshot = await FirebaseFirestore.instance
              .collection('items')
              .where('barcode', isEqualTo: scannedCode)
              .limit(1)
              .get();

          if (snapshot.docs.isEmpty) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Not Found'),
                content: Text('Nothing found. Please manually add the item.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            final data = snapshot.docs.first.data();
            final name = data['name'] ?? '';
            final productTag = data['productTag'] ?? '';
            final recipeTag = data['recipeTag'] ?? '';

            DateTime? selectedDate;

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20,
                          MediaQuery.of(ctx).viewInsets.bottom + 20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Text(
                              name,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text('Category: $productTag'),
                            Text('Recipe Tag: $recipeTag'),
                            SizedBox(height: 20),
                            Text('Expiration Date', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now.add(Duration(days: 7)),
                                  firstDate: now,
                                  lastDate: now.add(Duration(days: 365 * 5)),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  selectedDate == null
                                    ? 'Pick a date'
                                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.save),
                                label: Text('Product saved'),
                                onPressed: selectedDate == null
                                    ? null
                                    : () async {
                                        final userId = FirebaseAuth.instance.currentUser?.uid;
                                        if (userId == null) return;

                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .collection('products')
                                            .add({
                                          'name': name,
                                          'quantity': 1,
                                          'quantityUnit': 'piece(s)',
                                          'tag': productTag,
                                          'recipeTag': recipeTag,
                                          'expirationDate': Timestamp.fromDate(selectedDate!),
                                        });

                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Saved "$name" to the fridge.')),
                                        );

                                        setState(() {
                                          _imageFile = null;
                                          _detectedItems.clear();
                                          _result = 'No item detected yet.';
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

            );
          }
        }
      }
    } catch (e) {
      print('Barcode scan failed: $e');
    }
  }


  void _addToPantry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_detectedItems.join(', ')} to database')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [Text('Scan Receipt'), Spacer(), Icon(Icons.settings)],
        ),
        backgroundColor: Color(0xFF266041),
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
              child:
                  _imageFile == null
                      ? Center(
                        child: Text(
                          'No image selected',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
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
                  backgroundColor: Color(0xFF4D8C66),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Product added',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scanBarcode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4D8C66),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Scan Barcode',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
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
                final filePath =
                    '${tempDir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
          // Center square overlay
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
