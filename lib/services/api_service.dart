import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // You can change this base URL as needed for your environment
  static const String baseUrl = "http://localhost:8001";

  // Fetch Recipe Recommendations
  Future<Map<String, dynamic>> getRecipeRecommendation(List<String> ingredients) async {
    String ingredientQuery = ingredients.join(",");
    
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/recommend?ingredients=$ingredientQuery"),
        headers: {"Accept": "application/json"}
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("API Error (${response.statusCode}): ${response.body}");
        throw Exception("Failed to load recipe recommendations: ${response.statusCode}");
      }
    } catch (e) {
      print("Network Error: $e");
      throw Exception("Network error: $e");
    }
  }

  // Fetch Smart Shopping List Predictions
  Future<List<String>> getShoppingList(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/predict-shopping-list?user_id=$userId"),
        headers: {"Accept": "application/json"}
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug output
        print("API Response: $data");
        
        if (data.containsKey("recommended_items")) {
          return List<String>.from(data["recommended_items"]);
        } else if (data.containsKey("error")) {
          throw Exception(data["error"]);
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        print("API Error (${response.statusCode}): ${response.body}");
        throw Exception("Failed to load shopping list: ${response.statusCode}");
      }
    } catch (e) {
      print("Shopping List Error: $e");
      throw Exception("Error fetching shopping list: $e");
    }
  }
  
  // Simple API health check
  Future<bool> checkApiStatus() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}