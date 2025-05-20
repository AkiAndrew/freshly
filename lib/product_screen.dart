import 'package:flutter/material.dart';

// Model for Product
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
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    recipeTag = recipeTag ?? name.toLowerCase().trim();
}

// Main App
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FridgeManagerHomePage(),
    );
  }
}

class FridgeManagerHomePage extends StatefulWidget {
  const FridgeManagerHomePage({Key? key}) : super(key: key);

  @override
  State<FridgeManagerHomePage> createState() => _FridgeManagerHomePageState();
}

class _FridgeManagerHomePageState extends State<FridgeManagerHomePage> {
  final List<Product> _products = [];

  void _addNewProduct() async {
    final newProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );

    if (newProduct != null) {
      setState(() {
        _products.add(newProduct);
      });
    }
  }
  
  // Delete a product
  void _deleteProduct(int index) {
    final deletedProduct = _products[index];
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${deletedProduct.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _products.removeAt(index);
                });
                
                Navigator.of(context).pop();
                
                // Show snackbar with undo option
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${deletedProduct.name} deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        setState(() {
                          _products.insert(index, deletedProduct);
                        });
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  // Delete multiple products
  void _deleteMultipleProducts() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to delete')),
      );
      return;
    }
    
    // Show confirmation dialog with options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Products'),
          content: const Text('What would you like to delete?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                // Find expired products
                final now = DateTime.now();
                final expiredIndices = <int>[];
                
                for (int i = 0; i < _products.length; i++) {
                  if (_products[i].expirationDate != null && 
                      _products[i].expirationDate!.isBefore(now)) {
                    expiredIndices.add(i);
                  }
                }
                
                if (expiredIndices.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No expired products found')),
                  );
                  Navigator.of(context).pop();
                  return;
                }
                
                // Remove them in reverse order to avoid index shifting problems
                final deleted = <Product>[];
                for (int i = expiredIndices.length - 1; i >= 0; i--) {
                  deleted.add(_products.removeAt(expiredIndices[i]));
                }
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${deleted.length} expired products'),
                  ),
                );
                
                setState(() {});
              },
              child: const Text('EXPIRED ITEMS'),
            ),
            TextButton(
              onPressed: () {
                // Keep backup of products for undo
                final backupProducts = List<Product>.from(_products);
                
                setState(() {
                  _products.clear();
                });
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted all ${backupProducts.length} products'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        setState(() {
                          _products.addAll(backupProducts);
                        });
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: const Text('ALL ITEMS', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fridge Manager'),
      ),
      body: _products.isEmpty
          ? const Center(
              child: Text('No products yet. Add some!'),
            )
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Dismissible(
                  key: Key(product.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      _products.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} removed'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            setState(() {
                              _products.insert(index, product);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${product.quantity} ${product.quantityUnit}'),
                        if (product.expirationDate != null)
                          Text(
                            'Expires: ${_formatDate(product.expirationDate!)}',
                            style: TextStyle(
                              color: _isNearExpiry(product.expirationDate!) 
                                  ? Colors.red 
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
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
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProduct(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProduct,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Format date to a readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Check if product is near expiry (within 3 days)
  bool _isNearExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }
  
  // Edit an existing product
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
    }
  }

  Color _getTagColor(String tag) {
    // Return different colors based on tag category
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
}

class AddProductPage extends StatefulWidget {
  final Product? product;
  
  const AddProductPage({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _recipeTagController = TextEditingController();
  String _selectedTag = '';
  String _selectedUnit = 'piece(s)';
  DateTime? _expirationDate;
  String? _productId;
  bool _customRecipeTag = false;

  // List of available quantity units
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

  // Map of common products to their suggested tags
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

  // List of predefined tag categories
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
    
    // If editing an existing product, populate the form
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _quantityController.text = widget.product!.quantity.toString();
      _selectedTag = widget.product!.tag;
      _selectedUnit = widget.product!.quantityUnit;
      _expirationDate = widget.product!.expirationDate;
      _productId = widget.product!.id;
      _recipeTagController.text = widget.product!.recipeTag;
      
      // Check if recipe tag is different from name (custom)
      _customRecipeTag = widget.product!.recipeTag.toLowerCase().trim() != 
                         widget.product!.name.toLowerCase().trim();
    } else {
      // For new products, default recipe tag will be set when the form is submitted
      _recipeTagController.text = '';
    }
  }

  // Auto-suggest tag based on product name
  void _suggestTag(String productName) {
    final lowerCaseName = productName.toLowerCase();
    
    // Check if the product name is in our suggestions
    for (final entry in _productTagSuggestions.entries) {
      if (lowerCaseName.contains(entry.key)) {
        setState(() {
          _selectedTag = entry.value;
        });
        return;
      }
    }
    
    // Default to 'Other' if no match found
    if (_selectedTag.isEmpty) {
      setState(() {
        _selectedTag = 'Other';
      });
    }
  }

  // Show date picker for expiration date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)), // 2 years ahead
    );
    
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  // Format date to a readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add New Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Only suggest tag if this is a new product
                  if (widget.product == null && value.length > 2) {
                    _suggestTag(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Recipe Tag field with toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recipe Tag:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          // Reset to product name when toggled off
                          _recipeTagController.text = _nameController.text.toLowerCase().trim();
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
                      border: OutlineInputBorder(),
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
                  // Quantity field
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Unit dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUnit,
                      items: _quantityUnits.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUnit = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Expiration date picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiration Date (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expirationDate == null 
                            ? 'Select a date' 
                            : _formatDate(_expirationDate!),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Tag (Category):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _tagCategories.map((tag) {
                  return ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTag = selected ? tag : '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedTag.isNotEmpty) {
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
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: Text(widget.product == null ? 'Add Product' : 'Save Changes'),
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