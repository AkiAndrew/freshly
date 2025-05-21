import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ----------- Product Model -----------
class Product {
  final String id;
  final String name;
  final int quantity;
  final String quantityUnit;
  final String tag;
  final String recipeTag;
  final DateTime? expirationDate;

  Product({
    String? id,
    required this.name,
    required this.quantity,
    required this.quantityUnit,
    required this.tag,
    String? recipeTag,
    this.expirationDate,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        recipeTag = recipeTag ?? name.toLowerCase().trim();
}

// ----------- Product Screen with Firebase Integration -----------
class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final List<Product> _products = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductsFromFirestore();
  }

  Future<void> _loadProductsFromFirestore() async {
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .get();

      final loadedProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'],
          quantity: data['quantity'],
          quantityUnit: data['quantityUnit'],
          tag: data['tag'],
          recipeTag: data['recipeTag'],
          expirationDate: data['expirationDate'] != null
              ? (data['expirationDate'] as Timestamp).toDate()
              : null,
        );
      }).toList();

      setState(() {
        _products.clear();
        _products.addAll(loadedProducts);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProductToFirestore(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final productRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .doc(product.id);

    await productRef.set({
      'name': product.name,
      'quantity': product.quantity,
      'quantityUnit': product.quantityUnit,
      'tag': product.tag,
      'recipeTag': product.recipeTag,
      'expirationDate': product.expirationDate != null
          ? Timestamp.fromDate(product.expirationDate!)
          : null,
    });
  }

  Future<void> _deleteProductFromFirestore(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final productRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .doc(productId);

    try {
      await productRef.delete();
      print('Deleted product with id $productId from Firestore');
    } catch (e) {
      print('Failed to delete product $productId: $e');
      rethrow;
    }
  }

  Future<void> _clearAllProductsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collectionRef =
        _firestore.collection('users').doc(user.uid).collection('products');

    final snapshots = await collectionRef.get();
    final batch = _firestore.batch();

    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  void _addNewProduct() async {
    final newProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );

    if (newProduct != null) {
      setState(() {
        _products.add(newProduct);
      });
      await _saveProductToFirestore(newProduct);
    }
  }

  void _editProduct(int index) async {
    final editedProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (context) => AddProductPage(product: _products[index]),
      ),
    );
    if (editedProduct != null) {
      setState(() {
        _products[index] = editedProduct;
      });
      await _saveProductToFirestore(editedProduct);
    }
  }

  void _deleteProduct(int index) async {
    final deletedProduct = _products[index];
    setState(() {
      _products.removeAt(index);
    });

    try {
      await _deleteProductFromFirestore(deletedProduct.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${deletedProduct.name} removed'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              setState(() {
                _products.insert(index, deletedProduct);
              });
              await _saveProductToFirestore(deletedProduct);
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _products.insert(index, deletedProduct);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  void _clearAllProducts() async {
    if (_products.isEmpty) return;

    final backupProducts = List<Product>.from(_products);

    setState(() {
      _products.clear();
    });

    try {
      await _clearAllProductsFromFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All products cleared'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              setState(() {
                _products.addAll(backupProducts);
              });
              for (final product in backupProducts) {
                await _saveProductToFirestore(product);
              }
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _products.addAll(backupProducts);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear all products: $e')),
      );
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'vegetable':
        return Colors.green.shade100;
      case 'fruit':
        return Colors.orange.shade100;
      case 'dairy':
        return Colors.blue.shade100;
      case 'meat':
        return Colors.red.shade100;
      case 'cereal':
        return Colors.amber.shade100;
      case 'beverage':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isNearExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _products.isEmpty ? null : _clearAllProducts,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _products.isEmpty
        ? const Center(child: Text('No products added yet.'))
        : ListView.builder(
            itemCount: _products.length,
            itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Flexible(
            child: Text(
              product.name,
              overflow: TextOverflow.ellipsis,
            ),
              ),
              subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quantity: ${product.quantity} ${product.quantityUnit}',
                overflow: TextOverflow.ellipsis,
              ),
              if (product.expirationDate != null)
                Text(
              'Expires: ${_formatDate(product.expirationDate!)}',
              style: TextStyle(
                color: _isNearExpiry(product.expirationDate!)
                ? Colors.red
                : null,
              ),
              overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
              Chip(
                label: Text(product.tag),
                backgroundColor: _getTagColor(product.tag),
              ),
              Chip(
                label: Text(product.recipeTag),
                backgroundColor: Colors.amber.shade100,
              ),
                ],
              ),
            ],
              ),
              trailing: SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit),
              onPressed: () => _editProduct(index),
                ),
                IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProduct(index),
                ),
              ],
            ),
              ),
            ),
          );
            },
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProduct,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
        );
      }
    }

// ----------- AddProductPage -----------
class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _recipeTagController = TextEditingController();

  String _selectedTag = 'Other';
  String _selectedUnit = 'piece(s)';
  DateTime? _expirationDate;
  String? _productId;
  bool _customRecipeTag = false;

  final List<String> _quantityUnits = [
    'piece(s)',
    'gram(s)',
    'kg',
    'ml',
    'liter(s)',
    'package(s)',
    'can(s)',
    'bottle(s)',
    'box(es)',
  ];

  final Map<String, String> _productTagSuggestions = {
    'apple': 'Fruit',
    'banana': 'Fruit',
    'orange': 'Fruit',
    'strawberry': 'Fruit',
    'broccoli': 'Vegetable',
    'carrot': 'Vegetable',
    'spinach': 'Vegetable',
    'lettuce': 'Vegetable',
    'milk': 'Dairy',
    'cheese': 'Dairy',
    'yogurt': 'Dairy',
    'butter': 'Dairy',
    'chicken': 'Meat',
    'beef': 'Meat',
    'pork': 'Meat',
    'fish': 'Meat',
    'cereal': 'Cereal',
    'oats': 'Cereal',
    'granola': 'Cereal',
    'kellogg': 'Cereal',
    'cheerios': 'Cereal',
    'water': 'Beverage',
    'juice': 'Beverage',
    'soda': 'Beverage',
    'coffee': 'Beverage',
    'tea': 'Beverage',
  };

  final List<String> _tagCategories = [
    'Vegetable',
    'Fruit',
    'Dairy',
    'Meat',
    'Cereal',
    'Beverage',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _quantityController.text = widget.product!.quantity.toString();
      _selectedTag = widget.product!.tag;
      _selectedUnit = widget.product!.quantityUnit;
      _expirationDate = widget.product!.expirationDate;
      _productId = widget.product!.id;
      _recipeTagController.text = widget.product!.recipeTag;

      _customRecipeTag = widget.product!.recipeTag.toLowerCase().trim() !=
          widget.product!.name.toLowerCase().trim();
    } else {
      _recipeTagController.text = '';
    }
  }

  void _suggestTag(String productName) {
    final lowerCaseName = productName.toLowerCase();

    for (final entry in _productTagSuggestions.entries) {
      if (lowerCaseName.contains(entry.key)) {
        setState(() {
          _selectedTag = entry.value;
        });
        return;
      }
    }

    if (_selectedTag.isEmpty) {
      setState(() {
        _selectedTag = 'Other';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.product == null ? 'Add Product' : 'Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter product name'
                    : null,
                onChanged: (value) {
                  if (widget.product == null && value.length > 2) {
                    _suggestTag(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recipe Tag:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 16,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Used for recipe recommendations',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _customRecipeTag,
                    onChanged: (value) {
                      setState(() {
                        _customRecipeTag = value;
                        if (!value) {
                          _recipeTagController.text =
                              _nameController.text.toLowerCase().trim();
                        }
                      });
                    },
                  ),
                  const Text('Custom'),
                ],
              ),
              AnimatedCrossFade(
                firstChild: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Recipe tag will be "${_nameController.text.toLowerCase().trim() == '' ? 'same as product name' : _nameController.text.toLowerCase().trim()}"',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                secondChild: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _recipeTagController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Recipe Tag',
                      hintText: 'Enter a custom recipe tag',
                    ),
                  ),
                ),
                crossFadeState: _customRecipeTag
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Unit'),
                      value: _selectedUnit,
                      items: _quantityUnits.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value ?? 'piece(s)';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_expirationDate == null
                    ? 'Select Expiry Date'
                    : 'Expiry: ${_formatDate(_expirationDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tagCategories.map((tag) {
                  return ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTag = selected ? tag : 'Other';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedTag.isNotEmpty) {
                    final product = Product(
                      id: _productId,
                      name: _nameController.text,
                      quantity: int.parse(_quantityController.text),
                      quantityUnit: _selectedUnit,
                      tag: _selectedTag,
                      recipeTag: _customRecipeTag
                          ? _recipeTagController.text.trim()
                          : _nameController.text.toLowerCase().trim(),
                      expirationDate: _expirationDate,
                    );
                    Navigator.of(context).pop(product);
                  } else if (_selectedTag.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a product tag')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child:
                    Text(widget.product == null ? 'Add Product' : 'Save Changes'),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _recipeTagController.dispose();
    super.dispose();
  }
}
