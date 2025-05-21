import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuRecommendPage extends StatefulWidget {
  @override
  _MenuRecommendPageState createState() => _MenuRecommendPageState();
}

class _MenuRecommendPageState extends State<MenuRecommendPage> {
  // User pantry items
  List<String> pantryItems = [];
  bool isLoading = true;

  // Recipes database
  final List<Map<String, dynamic>> recipes = [
    {
      'name': 'Tomato Omelette',
      'ingredients': ['egg', 'tomato', 'salt'],
      'instructions':
          '1. Beat eggs in a bowl\n2. Dice tomatoes\n3. Cook eggs in a pan\n4. Add tomatoes and salt',
    },
    {
      'name': 'Fried Rice',
      'ingredients': ['rice', 'egg', 'onion', 'soy sauce'],
      'instructions':
          '1. Cook rice\n2. Fry chopped onions\n3. Add beaten eggs\n4. Mix in cooked rice and soy sauce',
    },
    {
      'name': 'Chicken Sandwich',
      'ingredients': ['chicken', 'bread', 'mayonnaise'],
      'instructions':
          '1. Cook chicken\n2. Spread mayonnaise on bread\n3. Place chicken between bread slices',
    },
    {
      'name': 'Simple Salad',
      'ingredients': ['tomato', 'cucumber', 'olive oil'],
      'instructions':
          '1. Dice tomatoes and cucumbers\n2. Drizzle with olive oil\n3. Season with salt and pepper',
    },
    {
      'name': 'Basic Stir Fry',
      'ingredients': ['chicken', 'onion', 'bell pepper', 'soy sauce'],
      'instructions':
          '1. Slice chicken and vegetables\n2. Stir fry chicken until cooked\n3. Add vegetables\n4. Season with soy sauce',
    },
  ];

  List<String> selectedItems = [];
  List<Map<String, dynamic>> matchedRecipes = [];

  @override
  void initState() {
    super.initState();
    fetchPantryItems();
  }

  // Fetch user's pantry items from Firestore
  Future<void> fetchPantryItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the current user ID
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'default';

      // Fetch pantry items from Firestore
      final snapshot =
          await FirebaseFirestore.instance
              .collection('pantry')
              .doc(userId)
              .get();

      List<String> items = [];

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('items')) {
          items = List<String>.from(data['items']);
        }
      } else {
        // If document doesn't exist, create it with default items
        items = [
          'egg',
          'tomato',
          'rice',
          'onion',
          'chicken',
          'bread',
          'cucumber',
          'bell pepper',
          'olive oil',
          'soy sauce',
          'mayonnaise',
          'salt',
        ];

        // Save default items to Firestore
        await FirebaseFirestore.instance.collection('pantry').doc(userId).set({
          'items': items,
        });
      }

      setState(() {
        pantryItems = items;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching pantry items: $e');
      setState(() {
        // Fallback to default items if there's an error
        pantryItems = [
          'egg',
          'tomato',
          'rice',
          'onion',
          'chicken',
          'bread',
          'cucumber',
          'bell pepper',
          'olive oil',
          'soy sauce',
        ];
        isLoading = false;
      });
    }
  }

  // Save a favorite recipe to Firestore
  Future<void> saveRecipe(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'default';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_recipes')
          .add({
            'name': recipe['name'],
            'ingredients': recipe['ingredients'],
            'instructions': recipe['instructions'],
            'saved_at': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Recipe saved successfully!')));
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save recipe.')));
    }
  }

  // Logic to check if recipe can be made
  void recommendRecipes() {
    List<Map<String, dynamic>> results = [];

    for (var recipe in recipes) {
      final recipeIngredients = List<String>.from(recipe['ingredients']);
      final canMake = recipeIngredients.every(
        (ingredient) => selectedItems.contains(ingredient),
      );

      if (canMake) {
        results.add(recipe);
      }
    }

    setState(() {
      matchedRecipes = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu Recommendation')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Ingredients You Have:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            pantryItems.map((item) {
                              final isSelected = selectedItems.contains(item);
                              return FilterChip(
                                label: Text(item),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedItems.add(item);
                                    } else {
                                      selectedItems.remove(item);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: recommendRecipes,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Text(
                              'Find Recipes',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      if (matchedRecipes.isNotEmpty) ...[
                        Text(
                          'Recommended Recipes:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        ...matchedRecipes.map(
                          (recipe) => _buildRecipeCard(recipe),
                        ),
                      ] else if (selectedItems.isNotEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No matching recipes found with selected ingredients.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          recipe['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${recipe['ingredients'].length} ingredients'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.bookmark_outline),
              tooltip: 'Save Recipe',
              onPressed: () => saveRecipe(recipe),
            ),
            Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingredients:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children:
                      (recipe['ingredients'] as List).map((ingredient) {
                        final bool isAvailable = selectedItems.contains(
                          ingredient,
                        );
                        return Chip(
                          label: Text(ingredient),
                          backgroundColor:
                              isAvailable
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                        );
                      }).toList(),
                ),
                SizedBox(height: 12),
                Text(
                  'Preparation:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(recipe['instructions']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
