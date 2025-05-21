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
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        recipeTag = recipeTag ?? name.toLowerCase().trim();
}

class ProductScreen extends StatefulWidget {
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
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

  void _deleteProduct(int index) {
    final deletedProduct = _products[index];
    setState(() {
      _products.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedProduct.name} removed'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _products.insert(index, deletedProduct);
            });
          },
        ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Product Manager'),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _products.isEmpty
                  ? null
                  : () => setState(() => _products.clear()),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _products.isEmpty
                  ? Center(child: Text('No products added yet.'))
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
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editProduct(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProduct(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNewProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add Product', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 20), // 👈 adds vertical space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/scanner'); // 👈 using named route
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Scan Barcode', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  final Product? product;
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(text: 'piece(s)');
  DateTime? _expirationDate;
  String _selectedTag = 'Other';

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _quantityController.text = widget.product!.quantity.toString();
      _unitController.text = widget.product!.quantityUnit;
      _expirationDate = widget.product!.expirationDate;
      _selectedTag = widget.product!.tag;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Add Product' : 'Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Enter valid quantity' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(labelText: 'Unit (e.g. gram, ml, piece)'),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_expirationDate == null ? 'Select Expiry Date' : 'Expiry: ${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTag,
                decoration: InputDecoration(labelText: 'Product Category'),
                items: ['Vegetable', 'Fruit', 'Dairy', 'Meat', 'Cereal', 'Beverage', 'Other']
                    .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedTag = value ?? 'Other'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final product = Product(
                      name: _nameController.text,
                      quantity: int.parse(_quantityController.text),
                      quantityUnit: _unitController.text,
                      tag: _selectedTag,
                      expirationDate: _expirationDate,
                    );
                    Navigator.of(context).pop(product);
                  }
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
                child: Text(widget.product == null ? 'Add Product' : 'Save Changes'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
