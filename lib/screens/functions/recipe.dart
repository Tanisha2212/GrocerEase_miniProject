import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Recipe extends StatefulWidget {
  const Recipe({super.key});

  @override
  _RecipeState createState() => _RecipeState();
}

class _RecipeState extends State<Recipe> {
  List<dynamic> _recipes = [];
  String _searchQuery = '';
  List<String> _selectedIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomRecipes();
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  Future<void> _fetchRandomRecipes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final url = Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php');
      List<dynamic> recipes = [];
      
      // Fetch 10 random recipes (API only returns 1 at a time)
      for (int i = 0; i < 10; i++) {
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            recipes.add(data['meals'][0]);
          }
        }
      }
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching random recipes: $e');
    }
  }

  Future<void> _searchRecipes() async {
    if (_searchQuery.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(_searchQuery)}'
      );
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recipes = data['meals'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _recipes = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error searching recipes: $e');
    }
  }

  Future<void> _searchByIngredients() async {
    if (_selectedIngredients.isEmpty) {
      _fetchRandomRecipes();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TheMealDB only allows searching by one ingredient at a time
      // We'll use the first ingredient from the list
      final ingredient = _selectedIngredients[0];
      final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/filter.php?i=${Uri.encodeComponent(ingredient)}'
      );
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<dynamic> detailedRecipes = [];
          
          // For each recipe ID, fetch the full details
          // We'll limit to first 10 to avoid too many requests
          final limit = data['meals'].length > 10 ? 10 : data['meals'].length;
          
          for (int i = 0; i < limit; i++) {
            final id = data['meals'][i]['idMeal'];
            final detailUrl = Uri.parse(
              'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id'
            );
            final detailResponse = await http.get(detailUrl);
            
            if (detailResponse.statusCode == 200) {
              final detailData = json.decode(detailResponse.body);
              if (detailData['meals'] != null && detailData['meals'].isNotEmpty) {
                // Only include recipes that contain all selected ingredients
                if (_selectedIngredients.length > 1) {
                  final recipe = detailData['meals'][0];
                  bool containsAllIngredients = true;
                  
                  for (int j = 1; j < _selectedIngredients.length; j++) {
                    bool found = false;
                    for (int k = 1; k <= 20; k++) {
                      final ing = recipe['strIngredient$k'];
                      if (ing != null && ing.toString().isNotEmpty && 
                          ing.toString().toLowerCase().contains(_selectedIngredients[j].toLowerCase())) {
                        found = true;
                        break;
                      }
                    }
                    if (!found) {
                      containsAllIngredients = false;
                      break;
                    }
                  }
                  
                  if (containsAllIngredients) {
                    detailedRecipes.add(recipe);
                  }
                } else {
                  detailedRecipes.add(detailData['meals'][0]);
                }
              }
            }
          }
          
          setState(() {
            _recipes = detailedRecipes;
            _isLoading = false;
          });
        } else {
          setState(() {
            _recipes = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _recipes = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error searching by ingredients: $e');
    }
  }

  void _addIngredient(String ingredient) {
    if (ingredient.isNotEmpty && !_selectedIngredients.contains(ingredient)) {
      setState(() {
        _selectedIngredients.add(ingredient);
        _ingredientController.clear();
      });
      _searchByIngredients();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
    _searchByIngredients();
  }

  List<String> _getIngredientsList(dynamic recipe) {
    List<String> ingredients = [];
    
    for (int i = 1; i <= 20; i++) {
      final ingredient = recipe['strIngredient$i'];
      final measure = recipe['strMeasure$i'];
      
      if (ingredient != null && ingredient.toString().isNotEmpty) {
        if (measure != null && measure.toString().isNotEmpty) {
          ingredients.add('$measure $ingredient');
        } else {
          ingredients.add(ingredient);
        }
      }
    }
    
    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar with search icon inside
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                _searchRecipes(); // Perform search when user hits "enter"
              },
              decoration: InputDecoration(
                hintText: 'Search for a recipe',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchRecipes,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ingredient selector section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      hintText: 'Add ingredient',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _addIngredient(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addIngredient(_ingredientController.text);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Selected ingredients chips
            if (_selectedIngredients.isNotEmpty)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedIngredients.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(_selectedIngredients[index]),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          _removeIngredient(_selectedIngredients[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Recipe results
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty 
                ? const Center(child: Text('No recipes found'))
                : ListView.builder(
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      final ingredients = _getIngredientsList(recipe);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(recipe['strMeal']),
                          subtitle: Text(
                            ingredients.take(3).join(', ') + 
                            (ingredients.length > 3 ? '...' : ''),
                          ),
                          trailing: recipe['strMealThumb'] != null
                            ? Image.network(
                                recipe['strMealThumb'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported);
                                },
                              )
                            : const Icon(Icons.image_not_supported),
                          onTap: () {
                            // Navigate to detailed recipe view if needed
                          },
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