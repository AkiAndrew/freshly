import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeScreen extends StatefulWidget {
  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _tags = [];

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addRecipe() async {
    final String name = _nameController.text.trim();
    final String imageUrl = _imageController.text.trim();
    final String tagsString = _tags.join(',');

    if (name.isEmpty || _tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      await _firestore.collection('recipes').add({
        'name': name,
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        'recipeTag': tagsString,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Recipe added successfully')));

      _nameController.clear();
      _imageController.clear();
      _tagController.clear();
      setState(() {
        _tags.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add recipe: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Recipe into Database'),
        backgroundColor: Color(0xFF266041),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Recipe Name'),
            ),
            TextField(
              controller: _imageController,
              decoration: InputDecoration(labelText: 'Image URL'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(labelText: 'Ingredient Tag'),
                  ),
                ),
                IconButton(icon: Icon(Icons.add), onPressed: _addTag),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children:
                  _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _addRecipe,
                child: Text('Add Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4D8C66),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
