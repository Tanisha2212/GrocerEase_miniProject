import 'package:flutter/material.dart';
import 'package:plswork/services/api_service.dart';

class SmartShoppingList extends StatefulWidget {
  const SmartShoppingList({super.key});

  @override
  _SmartShoppingListState createState() => _SmartShoppingListState();
}

class _SmartShoppingListState extends State<SmartShoppingList> {
  final ApiService _apiService = ApiService();
  List<String> shoppingList = [];
  List<bool> checkedItems = []; // Track checked items
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "Failed to load shopping list. Please try again.";
  bool isApiAvailable = false;
  List<String> cartItems = [];

  @override
  void initState() {
    super.initState();
    checkApiAndFetchData();
  }

  Future<void> checkApiAndFetchData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      isApiAvailable = await _apiService.checkApiStatus();

      if (!isApiAvailable) {
        setState(() {
          hasError = true;
          errorMessage = "API server is not available. Please check your connection.";
          isLoading = false;
        });
        return;
      }

      await fetchShoppingList();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = "Connection error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> fetchShoppingList() async {
    try {
      final items = await _apiService.getShoppingList("user1");

      setState(() {
        shoppingList = items;
        checkedItems = List.generate(items.length, (index) => false); // Initialize checked items
        isLoading = false;
        hasError = false;
      });

      print("Shopping list fetched successfully: $shoppingList");
    } catch (e) {
      print("Error details: $e");
      setState(() {
        hasError = true;
        errorMessage = "Failed to load shopping list: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  void addToCart(String item) {
    setState(() {
      cartItems.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added $item to cart")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Shopping List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: checkApiAndFetchData,
            tooltip: "Refresh List",
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(cartItems: cartItems),
                ),
              );
            },
            tooltip: "View Cart",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                "AI-powered recommendations based on your purchase history",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading your personalized shopping list...")
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: checkApiAndFetchData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (shoppingList.isEmpty) {
      return const Center(
        child: Text(
          "No items to recommend at this time.\nCheck back later!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: shoppingList.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                shoppingList[index][0].toUpperCase(),
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
            title: Text(shoppingList[index], style: const TextStyle(fontSize: 16)),
            trailing: Checkbox(
              value: checkedItems[index],
              onChanged: (bool? value) {
                setState(() {
                  checkedItems[index] = value!;
                  if(value == true){
                    addToCart(shoppingList[index]);
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }
}

class CartPage extends StatelessWidget {
  final List<String> cartItems;

  const CartPage({Key? key, required this.cartItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),
      body: cartItems.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(cartItems[index]));
              },
            ),
    );
  }
}