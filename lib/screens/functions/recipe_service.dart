import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeService {
  final String applicationId = '5fa28931'; // Replace with your Application ID
  final String applicationKey = 'e1c4a8971f2b361be3e61249db2b9033'; // Replace with your Application Key

  // This method fetches recipes based on a query string
  Future<List<dynamic>> searchRecipes(String query) async {
    final url =
        'https://api.edamam.com/search?q=$query&app_id=$applicationId&app_key=$applicationKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['hits']; // Return the list of recipe hits
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  // This method fetches recipes based on a list of inventory items
  Future<List<dynamic>> suggestRecipes(List<String> inventory) async {
    final ingredients = inventory.join(','); // Join inventory items into a string
    return await searchRecipes(ingredients); // Use the searchRecipes method
  }
}
