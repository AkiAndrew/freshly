import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Extension to capitalize strings - MOVED TO TOP
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Helper function as a backup
String capitalizeString(String text) {
  if (text.isEmpty) return text;
  return "${text[0].toUpperCase()}${text.substring(1)}";
}

class ItemScreen extends StatefulWidget {
  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class ItemListView extends StatefulWidget {
  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  String _searchFilter = '';
  String _categoryFilter = 'all';

  final List<String> _categories = [
    'all',
    'vegetables',
    'fruits',
    'meat',
    'dairy',
    'cereal',
    'beverage',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item List'),
        backgroundColor: Color(0xFF266041),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search items',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchFilter = value.toLowerCase();
                    });
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _categoryFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                      _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category == 'all'
                                ? 'All Categories'
                                : capitalizeString(category),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _categoryFilter = newValue ?? 'all';
                    });
                  },
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('items')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data?.docs ?? [];

                // Apply filters
                final filteredItems =
                    items.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();
                      final productTag =
                          (data['productTag'] ?? '').toString().toLowerCase();

                      // Search filter
                      final matchesSearch =
                          _searchFilter.isEmpty ||
                          name.contains(_searchFilter) ||
                          productTag.contains(_searchFilter);

                      // Category filter
                      final matchesCategory =
                          _categoryFilter == 'all' ||
                          productTag == _categoryFilter;

                      return matchesSearch && matchesCategory;
                    }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchFilter.isEmpty && _categoryFilter == 'all'
                              ? 'No items found.\nStart adding items!'
                              : 'No items match your filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final doc = filteredItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown Item';
                    final productTag = data['productTag'] ?? 'unknown';
                    final recipeTag = data['recipeTag'] ?? '';
                    final barcode = data['barcode'];
                    final createdAt = data['createdAt'] as Timestamp?;

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(productTag),
                          child: Icon(
                            _getCategoryIcon(productTag),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${capitalizeString(productTag)}',
                              style: TextStyle(
                                color: _getCategoryColor(productTag),
                              ),
                            ),
                            Text('Recipe tag: $recipeTag'),
                            if (barcode != null) Text('Barcode: $barcode'),
                            if (createdAt != null)
                              Text('Added: ${_formatDate(createdAt.toDate())}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteItem(doc.id, name);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.orange;
      case 'meat':
        return Colors.red;
      case 'dairy':
        return Colors.blue;
      case 'cereal':
        return Colors.brown;
      case 'beverage':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'meat':
        return Icons.lunch_dining;
      case 'dairy':
        return Icons.local_drink;
      case 'cereal':
        return Icons.grain;
      case 'beverage':
        return Icons.local_cafe;
      default:
        return Icons.inventory;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _deleteItem(String docId, String itemName) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Item'),
            content: Text('Are you sure you want to delete "$itemName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('items')
                        .doc(docId)
                        .delete();
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Item deleted successfully')),
                    );
                  } catch (e) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting item: $e')),
                    );
                  }
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

class _ItemScreenState extends State<ItemScreen> {
  File? _imageFile;
  String? _result = 'Item Image';
  bool _isDetecting = false;
  List<String> _detectedItems = [];
  final ImagePicker _picker = ImagePicker();

  // Available product categories
  final List<String> _productCategories = [
    'vegetables',
    'fruits',
    'meat',
    'dairy',
    'cereal',
    'beverage',
  ];

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
          _showManualEntryDialog(scannedCode, image);
        }
      }
    } catch (e) {
      print('Barcode scan failed: $e');
    }
  }

  void _showManualEntryDialog(String barcode, [File? image]) {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _recipeTagController = TextEditingController();
    String? _selectedProductTag;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
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
                        SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _selectedProductTag,
                          decoration: InputDecoration(
                            labelText: 'Product Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _productCategories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(capitalizeString(category)),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _selectedProductTag = newValue;
                            });
                          },
                          hint: Text('Select category'),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _recipeTagController,
                          decoration: InputDecoration(
                            labelText: 'Recipe Tag',
                            hintText: 'e.g., apple, cheese, chicken',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final recipeTag = _recipeTagController.text.trim();

                        if (name.isEmpty ||
                            _selectedProductTag == null ||
                            recipeTag.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        // Check for duplicate barcode
                        final existing =
                            await FirebaseFirestore.instance
                                .collection('items')
                                .where('barcode', isEqualTo: barcode)
                                .get();

                        if (existing.docs.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Item with this barcode already exists',
                              ),
                            ),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('items')
                            .add({
                              'name': name,
                              'barcode': barcode,
                              'productTag': _selectedProductTag,
                              'recipeTag': recipeTag.toLowerCase(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                        Navigator.of(ctx).pop();

                        // Reset everything after dialog is closed
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
          ),
    );
  }

  void _showCreateItemDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _recipeTagController = TextEditingController();
    String? _selectedProductTag;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Create Item Without Barcode'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            hintText: 'e.g., Apple, Chicken, Milk',
                          ),
                        ),
                        SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _selectedProductTag,
                          decoration: InputDecoration(
                            labelText: 'Product Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _productCategories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(capitalizeString(category)),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _selectedProductTag = newValue;
                            });
                          },
                          hint: Text('Select category'),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _recipeTagController,
                          decoration: InputDecoration(
                            labelText: 'Recipe Tag',
                            hintText: 'e.g., apple, cheese, chicken',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final recipeTag = _recipeTagController.text.trim();

                        if (name.isEmpty ||
                            _selectedProductTag == null ||
                            recipeTag.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('items')
                            .add({
                              'name': name,
                              'barcode':
                                  null, // No barcode for manually created items
                              'productTag': _selectedProductTag,
                              'recipeTag': recipeTag.toLowerCase(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                        Navigator.of(ctx).pop();

                        // Reset everything after dialog is closed
                        setState(() {
                          _imageFile = null;
                          _result = 'Item Image';
                          _detectedItems.clear();
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Item "$name" saved with category: ${capitalizeString(_selectedProductTag!)}',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      child: Text('Create Item'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _viewItemList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemListView()),
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
                          'No item scanned',
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
                onPressed: _viewItemList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4D8C66),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add to Database',
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
                'Scan Item Barcode',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showCreateItemDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4D8C66),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Item Without Barcode',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _viewItemList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4D8C66),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'View Item List',
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
