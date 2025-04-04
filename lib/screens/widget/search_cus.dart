import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:plswork/screens/widget/RecipeDetail.dart'; // Import RecipeDetail

class SearchCus extends StatefulWidget {
  final String cuisine; // Cuisine passed from Search page
  const SearchCus({super.key, required this.cuisine});

  @override
  State<SearchCus> createState() => _SearchCusState();
}

class _SearchCusState extends State<SearchCus> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/filter.php?a=${widget.cuisine}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _recipes = data['meals'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cuisine} Recipes'),
        backgroundColor: Colors.lightGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(child: Text('No recipes found.'))
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return ListTile(
                      leading: Image.network(
                        recipe['strMealThumb'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(recipe['strMeal']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetail(recipeId: recipe['idMeal']),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
