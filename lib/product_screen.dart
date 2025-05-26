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
  final DateTime expirationDate;

  Product({
    String? id,
    required this.name,
    required this.quantity,
    required this.quantityUnit,
    required this.tag,
    String? recipeTag,
    required this.expirationDate,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       recipeTag = recipeTag ?? name.toLowerCase().trim();
}

// ----------- Item Model for Firebase items collection -----------
class Item {
  final String name;
  final String productTag;
  final String recipeTag;
  final String? barcode;

  Item({
    required this.name,
    required this.productTag,
    required this.recipeTag,
    this.barcode,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      name: data['name'] ?? '',
      productTag: data['productTag'] ?? '',
      recipeTag: data['recipeTag'] ?? '',
      barcode: data['barcode'],
    );
  }
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
    _updateExpiryStats();
    _addSampleDataForReports();
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
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('products')
              .get();

      final loadedProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Product(
              id: doc.id,
              name: data['name'],
              quantity: data['quantity'],
              quantityUnit: data['quantityUnit'],
              tag: data['tag'],
              recipeTag: data['recipeTag'],
              expirationDate:
                  data['expirationDate'] != null
                      ? (data['expirationDate'] as Timestamp).toDate()
                      : DateTime.now().add(const Duration(days: 7)),
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
      'expirationDate': Timestamp.fromDate(product.expirationDate),
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
      // Get the product data before deleting
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        final productData = productDoc.data()!;

        // Show dialog to ask if the item was consumed or wasted
        final result = await showDialog<String>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('Item Removal'),
                content: Text('Was this item consumed or wasted?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop('consumed'),
                    child: Text('Consumed'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop('wasted'),
                    child: Text('Wasted'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop('delete'),
                    child: Text('Just Delete'),
                  ),
                ],
              ),
        );

        if (result == 'consumed' || result == 'wasted') {
          // Add to consumed_items or wasted_items collection
          await _firestore.collection('${result}_items').add({
            'name': productData['name'],
            'quantity': productData['quantity'],
            'tag': productData['tag'],
            'date': Timestamp.now(),
          });

          // Update food categories statistics
          final categoryRef = _firestore
              .collection('food_categories')
              .doc(productData['tag'].toLowerCase());
          await _firestore.runTransaction((transaction) async {
            final categoryDoc = await transaction.get(categoryRef);
            if (categoryDoc.exists) {
              final currentCount = categoryDoc.data()?['count'] ?? 0;
              transaction.update(categoryRef, {'count': currentCount + 1});
            } else {
              transaction.set(categoryRef, {
                'category': productData['tag'],
                'count': 1,
                'date': Timestamp.now(),
              });
            }
          });
        }
      }

      // Delete the product
      await productRef.delete();
      print('Deleted product with id $productId from Firestore');
    } catch (e) {
      print('Failed to delete product $productId: $e');
      rethrow;
    }
  }

  // Add method to update expiry statistics
  Future<void> _updateExpiryStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final nextWeek = now.add(Duration(days: 7));

      // Count expired and expiring items
      int expiredThisWeek = 0;
      int expiringNextWeek = 0;
      double moneySaved = 0;

      for (final product in _products) {
        if (product.expirationDate.isBefore(now)) {
          expiredThisWeek++;
        } else if (product.expirationDate.isBefore(nextWeek)) {
          expiringNextWeek++;
          // Assume average cost of $5 per item saved
          moneySaved += 5;
        }
      }

      // Update expiry stats
      await _firestore.collection('expiry_stats').add({
        'expired_this_week': expiredThisWeek,
        'expiring_next_week': expiringNextWeek,
        'money_saved': moneySaved,
        'date': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating expiry stats: $e');
    }
  }

  Future<void> _clearAllProductsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collectionRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products');

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
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

  // Add sample data for reports
  Future<void> _addSampleDataForReports() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Sample consumed items
      final consumedItems = [
        {
          'name': 'Chicken',
          'quantity': 3,
          'tag': 'Meat',
          'date': Timestamp.now(),
        },
        {
          'name': 'Rice',
          'quantity': 5,
          'tag': 'Cereal',
          'date': Timestamp.now(),
        },
        {
          'name': 'Milk',
          'quantity': 2,
          'tag': 'Dairy',
          'date': Timestamp.now(),
        },
        {
          'name': 'Apple',
          'quantity': 4,
          'tag': 'Fruit',
          'date': Timestamp.now(),
        },
        {
          'name': 'Bread',
          'quantity': 3,
          'tag': 'Cereal',
          'date': Timestamp.now(),
        },
      ];

      // Sample wasted items
      final wastedItems = [
        {
          'name': 'Tomato',
          'quantity': 2,
          'tag': 'Vegetable',
          'date': Timestamp.now(),
        },
        {
          'name': 'Yogurt',
          'quantity': 1,
          'tag': 'Dairy',
          'date': Timestamp.now(),
        },
        {
          'name': 'Banana',
          'quantity': 3,
          'tag': 'Fruit',
          'date': Timestamp.now(),
        },
        {
          'name': 'Lettuce',
          'quantity': 1,
          'tag': 'Vegetable',
          'date': Timestamp.now(),
        },
        {'name': 'Fish', 'quantity': 1, 'tag': 'Meat', 'date': Timestamp.now()},
      ];

      // Sample food categories
      final foodCategories = [
        {
          'category': 'Vegetable',
          'count': 15,
          'percentage': 25,
          'date': Timestamp.now(),
        },
        {
          'category': 'Fruit',
          'count': 12,
          'percentage': 20,
          'date': Timestamp.now(),
        },
        {
          'category': 'Meat',
          'count': 10,
          'percentage': 17,
          'date': Timestamp.now(),
        },
        {
          'category': 'Dairy',
          'count': 8,
          'percentage': 13,
          'date': Timestamp.now(),
        },
        {
          'category': 'Cereal',
          'count': 15,
          'percentage': 25,
          'date': Timestamp.now(),
        },
      ];

      // Add consumed items
      for (var item in consumedItems) {
        await _firestore.collection('consumed_items').add(item);
      }

      // Add wasted items
      for (var item in wastedItems) {
        await _firestore.collection('wasted_items').add(item);
      }

      // Add food categories
      for (var category in foodCategories) {
        await _firestore.collection('food_categories').add(category);
      }

      // Add expiry stats
      await _firestore.collection('expiry_stats').add({
        'expired_this_week': 3,
        'expiring_next_week': 5,
        'money_saved': 25.50,
        'date': Timestamp.now(),
      });

      print('Sample data added successfully');
    } catch (e) {
      print('Error adding sample data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _products.isEmpty ? null : _clearAllProducts,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _products.isEmpty
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editProduct(index),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteProduct(index),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quantity: ${product.quantity} ${product.quantityUnit}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expires: ${_formatDate(product.expirationDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _isNearExpiry(product.expirationDate)
                                        ? Colors.red
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  label: Text(
                                    product.tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: _getTagColor(product.tag),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                Chip(
                                  label: Text(
                                    product.recipeTag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.amber.shade100,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ],
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

// ----------- AddProductPage with Firebase Items Integration -----------
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

  // New variables for Firebase items integration
  List<Item> _suggestedItems = [];
  bool _isSearching = false;
  Item? _selectedItem;
  bool _showSuggestions = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  final List<String> _tagCategories = [
    'Vegetable',
    'Fruit',
    'Dairy',
    'Meat',
    'Cereal',
    'Beverage',
    'Other',
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

      _customRecipeTag =
          widget.product!.recipeTag.toLowerCase().trim() !=
          widget.product!.name.toLowerCase().trim();
    } else {
      _recipeTagController.text = '';
    }
  }

  // Search for items in Firebase
  Future<void> _searchItems(String productName) async {
    if (productName.trim().length < 2) {
      setState(() {
        _suggestedItems.clear();
        _showSuggestions = false;
        _selectedItem = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search for items with case-insensitive matching
      final snapshot =
          await _firestore
              .collection('items')
              .where('name', isGreaterThanOrEqualTo: productName.toLowerCase())
              .where(
                'name',
                isLessThanOrEqualTo: productName.toLowerCase() + '\uf8ff',
              )
              .limit(10)
              .get();

      final items =
          snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();

      // Also search for items that contain the search term
      if (items.isEmpty) {
        final allItemsSnapshot = await _firestore.collection('items').get();
        final allItems =
            allItemsSnapshot.docs
                .map((doc) => Item.fromFirestore(doc))
                .where(
                  (item) => item.name.toLowerCase().contains(
                    productName.toLowerCase(),
                  ),
                )
                .take(10)
                .toList();
        items.addAll(allItems);
      }

      setState(() {
        _suggestedItems = items;
        _showSuggestions = items.isNotEmpty;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching items: $e');
      setState(() {
        _isSearching = false;
        _suggestedItems.clear();
        _showSuggestions = false;
      });
    }
  }

  // Select an item from suggestions
  void _selectItem(Item item) {
    setState(() {
      _selectedItem = item;
      _nameController.text = item.name;
      _selectedTag = _capitalizeFirst(item.productTag);
      _recipeTagController.text = item.recipeTag;
      _showSuggestions = false;

      // If the recipe tag is different from the name, enable custom mode
      _customRecipeTag =
          item.recipeTag.toLowerCase().trim() != item.name.toLowerCase().trim();
    });
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Validation helper methods
  bool _isExpirationDateInvalid() {
    if (_expirationDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(
      _expirationDate!.year,
      _expirationDate!.month,
      _expirationDate!.day,
    );

    if (selectedDate.isBefore(today)) {
      return true;
    }

    final fiveYearsFromNow = today.add(const Duration(days: 365 * 5));
    if (selectedDate.isAfter(fiveYearsFromNow)) {
      return true;
    }

    return false;
  }

  String _getExpirationDateErrorMessage() {
    if (_expirationDate == null) return 'Expiration date is required';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(
      _expirationDate!.year,
      _expirationDate!.month,
      _expirationDate!.day,
    );

    if (selectedDate.isBefore(today)) {
      return 'Expiration date cannot be in the past';
    }

    final fiveYearsFromNow = today.add(const Duration(days: 365 * 5));
    if (selectedDate.isAfter(fiveYearsFromNow)) {
      return 'Expiration date cannot be more than 5 years in the future';
    }

    return '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Select expiration date',
      cancelText: 'Cancel',
      confirmText: 'Select',
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
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Product name field with suggestions
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter product name (e.g., Apple, Milk)',
                      suffixIcon:
                          _isSearching
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Product name must be at least 2 characters';
                      }
                      if (value.trim().length > 50) {
                        return 'Product name cannot exceed 50 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (widget.product == null) {
                        _searchItems(value);
                      }
                    },
                  ),
                  // Suggestions dropdown
                  if (_showSuggestions && _suggestedItems.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Suggestions from database:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ..._suggestedItems.map(
                            (item) => ListTile(
                              dense: true,
                              title: Text(item.name),
                              subtitle: Text(
                                '${_capitalizeFirst(item.productTag)} • ${item.recipeTag}',
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () => _selectItem(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Selected item indicator
                  if (_selectedItem != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${_selectedItem!.name} (${_capitalizeFirst(_selectedItem!.productTag)})',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _selectedItem = null;
                                _selectedTag = 'Other';
                                _recipeTagController.clear();
                                _customRecipeTag = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                          if (_selectedItem != null) {
                            _recipeTagController.text =
                                _selectedItem!.recipeTag;
                          } else {
                            _recipeTagController.text =
                                _nameController.text.toLowerCase().trim();
                          }
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
                    _selectedItem != null
                        ? 'Recipe tag: "${_selectedItem!.recipeTag}" (from database)'
                        : 'Recipe tag will be "${_nameController.text.toLowerCase().trim() == '' ? 'same as product name' : _nameController.text.toLowerCase().trim()}"',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                secondChild: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _recipeTagController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Recipe Tag',
                      border: OutlineInputBorder(),
                      hintText: 'Enter a custom recipe tag',
                    ),
                    validator:
                        _customRecipeTag
                            ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Custom recipe tag is required when custom mode is enabled';
                              }
                              if (value.trim().length < 2) {
                                return 'Recipe tag must be at least 2 characters';
                              }
                              if (value.trim().length > 30) {
                                return 'Recipe tag cannot exceed 30 characters';
                              }
                              return null;
                            }
                            : null,
                  ),
                ),
                crossFadeState:
                    _customRecipeTag
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
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        hintText: 'Enter quantity',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }

                        final quantity = int.tryParse(value.trim());
                        if (quantity == null) {
                          return 'Please enter a valid number';
                        }

                        if (quantity <= 0) {
                          return 'Quantity must be greater than 0';
                        }

                        if (quantity > 9999) {
                          return 'Quantity cannot exceed 9999';
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
                      items:
                          _quantityUnits.map((String unit) {
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
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _expirationDate == null
                            ? Colors.red.shade300
                            : Colors.grey.shade400,
                    width: _expirationDate == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        _expirationDate == null
                            ? 'Select Expiry Date'
                            : 'Expiry: ${_formatDate(_expirationDate!)}',
                        style: TextStyle(
                          color:
                              _expirationDate == null
                                  ? Colors.red.shade700
                                  : null,
                          fontWeight:
                              _expirationDate == null ? FontWeight.w500 : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: _expirationDate == null ? Colors.red.shade700 : null,
                  ),
                  onTap: () => _selectDate(context),
                ),
              ),
              if (_isExpirationDateInvalid())
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _getExpirationDateErrorMessage(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Product Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _tagCategories.map((tag) {
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
                  // Validate the form and check expiration date
                  if (_formKey.currentState!.validate() &&
                      _selectedTag.isNotEmpty &&
                      !_isExpirationDateInvalid()) {
                    // Additional validation for recipe tag if custom
                    if (_customRecipeTag &&
                        _recipeTagController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a custom recipe tag or turn off custom mode',
                          ),
                        ),
                      );
                      return;
                    }

                    String finalRecipeTag;
                    if (_customRecipeTag) {
                      finalRecipeTag = _recipeTagController.text.trim();
                    } else if (_selectedItem != null) {
                      finalRecipeTag = _selectedItem!.recipeTag;
                    } else {
                      finalRecipeTag =
                          _nameController.text.toLowerCase().trim();
                    }

                    final product = Product(
                      id: _productId,
                      name: _nameController.text.trim(),
                      quantity: int.parse(_quantityController.text.trim()),
                      quantityUnit: _selectedUnit,
                      tag: _selectedTag,
                      recipeTag: finalRecipeTag,
                      expirationDate: _expirationDate!,
                    );
                    Navigator.of(context).pop(product);
                  } else {
                    // Show specific error messages
                    if (_selectedTag.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a product category'),
                        ),
                      );
                    } else if (_isExpirationDateInvalid()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getExpirationDateErrorMessage()),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  widget.product == null ? 'Add Product' : 'Save Changes',
                ),
              ),
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
