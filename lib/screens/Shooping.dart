import 'package:flutter/material.dart';

class ShoppingPage extends StatelessWidget {
  final List<String> ingredients;

  const ShoppingPage({Key? key, required this.ingredients}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Shops'),
      ),
      body: ListView.builder(
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Order ${ingredients[index]} from nearby stores'),
            trailing: Icon(Icons.store_mall_directory),
            onTap: () {
              // Handle placing order for each ingredient
            },
          );
        },
      ),
    );
  }
}
