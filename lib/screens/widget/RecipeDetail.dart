import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'order_page.dart'; // Import OrderPage

class RecipeDetail extends StatefulWidget {
  final String recipeId;
  const RecipeDetail({super.key, required this.recipeId});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  Map<String, dynamic>? _recipeDetails;
  bool _isLoading = true;
  bool _isOrdering = false; // Flag for ordering ingredients

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.recipeId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _recipeDetails = data['meals'][0];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getIngredients() {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = _recipeDetails?['strIngredient$i'];
      final measure = _recipeDetails?['strMeasure$i'];
      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients.add('$ingredient - $measure');
      }
    }
    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipeDetails == null
              ? const Center(child: Text('Recipe not found.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Image
                    Image.network(
                      _recipeDetails!['strMealThumb'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _recipeDetails!['strMeal'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Ingredients:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Ingredients List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getIngredients().length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _getIngredients()[index],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Order Ingredients Button
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _isOrdering
                            ? null // Disable button when loading
                            : () async {
                                setState(() {
                                  _isOrdering = true;
                                });
                                // Navigate to Order Page
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderPage(
                                        ingredients: _getIngredients(), storeId: '',),
                                  ),
                                );
                                setState(() {
                                  _isOrdering = false;
                                });
                              },
                        child: _isOrdering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Order Ingredients'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
