import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  @override
  _RecipeRecommendationScreenState createState() =>
      _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState
    extends State<RecipeRecommendationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _matchingRecipes = [];
  bool _isLoading = false;
  String _selectedIngredient = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRecipes(String ingredient) async {
    if (ingredient.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _selectedIngredient = ingredient.trim().toLowerCase();
    });

    try {
      // Search for recipes in Firebase that contain the ingredient tag
      final QuerySnapshot recipesSnapshot =
          await FirebaseFirestore.instance
              .collection('recipes')
              .where('tags', arrayContains: _selectedIngredient)
              .get();

      setState(() {
        _matchingRecipes = recipesSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search recipes. Please try again.')),
      );
    }
  }

  void _showRecipeDetails(DocumentSnapshot recipe) {
    final data = recipe.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['name'] ?? 'Recipe Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (data['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      data['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                    ),
                  ),
                SizedBox(height: 20),
                Text(
                  'Ingredients:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (data['tags'] as String)
                          .split(',')
                          .map(
                            (tag) => Chip(
                              label: Text(tag.trim()),
                              backgroundColor: Color(0xFF4D8C66),
                              labelStyle: TextStyle(color: Color(0xFFC1FF72)),
                            ),
                          )
                          .toList(),
                ),
                SizedBox(height: 20),
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      data['instructions'] ?? 'No instructions available.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF1C1C1C)),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Recommendations'),
        backgroundColor: Color(0xFF266041),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter an ingredient (e.g., chicken, apple)',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _matchingRecipes = [];
                      _selectedIngredient = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF4D8C66), width: 2),
                ),
              ),
              onSubmitted: _searchRecipes,
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: Color(0xFF4D8C66)))
            else if (_matchingRecipes.isEmpty && _selectedIngredient.isNotEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_meals, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No recipes found with "$_selectedIngredient"',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else if (_matchingRecipes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _matchingRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _matchingRecipes[index];
                    final data = recipe.data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              data['imageUrl'] != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.restaurant,
                                            color: Color(0xFF4D8C66),
                                          ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.restaurant,
                                    color: Color(0xFF4D8C66),
                                  ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unnamed Recipe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        subtitle: Text(
                          'Tags: ${data['tags']}',
                          style: TextStyle(color: Color(0xFF1C1C1C)),
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => _showRecipeDetails(recipe),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
