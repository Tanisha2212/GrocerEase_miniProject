import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<String>> _fetchRecipeIngredients(String query) async {
  final appId = '5fa28931'; // Your Edamam Application ID
  final appKey = 'e1c4a8971f2b361be3e61249db2b9033'; // Your Edamam Application Key
  final url = Uri.parse(
      'https://api.edamam.com/search?q=pav%20bhaji&app_id=$appId&app_key=$appKey');

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    List<String> ingredients = [];

    // Assuming you are parsing the first recipe
    final firstRecipe = data['hits'][0]['recipe'];
    for (var ingredient in firstRecipe['ingredientLines']) {
      ingredients.add(ingredient.toString());
    }

    return ingredients;
  } else {
    throw Exception('Failed to fetch recipe ingredients');
  }
}
