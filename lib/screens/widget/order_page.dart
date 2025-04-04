import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderPage extends StatefulWidget {
  final String storeId;
  final List<String> ingredients;

  OrderPage({required this.storeId, required this.ingredients});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Map<String, dynamic>> nearbyStores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyStores();
  }

  Future<void> _fetchNearbyStores() async {
    // Fetch user's current location
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _getNearbyStores(position.latitude, position.longitude);
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getNearbyStores(double latitude, double longitude) async {
    final String apiKey = 'fsq3hij2i1l+zuoTuhXO3F181P/WbRuxlBmdsWPGgWWwBxw='; // Your Foursquare API key
    final String apiUrl = 'https://api.foursquare.com/v3/places/search?ll=$latitude,$longitude&radius=15000&categories=13029,13037,13000'; // Supermarkets and Grocery Stores

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': apiKey,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> stores = data['results'];

        setState(() {
          nearbyStores = stores.map((store) {
            String imageUrl = store['photos'] != null && store['photos'].isNotEmpty
                ? '${store['photos'][0]['prefix']}300x300${store['photos'][0]['suffix']}'
                : 'https://via.placeholder.com/150'; // Placeholder image

            return {
              'name': store['name'] ?? 'Unknown Store',
              'type': store['categories'] != null && store['categories'].isNotEmpty
                  ? store['categories'][0]['name']
                  : 'Unknown Type',
              'latitude': store['geocodes']['main']['latitude'],
              'longitude': store['geocodes']['main']['longitude'],
              'image': imageUrl,
              'id': store['id'], // Store ID to pass to the order page
            };
          }).toList();
        });
      } else {
        print('Failed to fetch nearby stores.');
      }
    } catch (e) {
      print('Error fetching stores: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToStoreSelection() {
    // Navigate to the store selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreSelectionPage(nearbyStores: nearbyStores, ingredients: widget.ingredients),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order from Store'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order from Store ID: ${widget.storeId}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Ingredients:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Display the list of ingredients
            for (var ingredient in widget.ingredients)
              Text(
                '- ${ingredient.trim()}',
                style: TextStyle(fontSize: 16),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToStoreSelection,
              child: Text('Select Store'),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreSelectionPage extends StatelessWidget {
  final List<Map<String, dynamic>> nearbyStores;
  final List<String> ingredients;

  StoreSelectionPage({required this.nearbyStores, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Store'),
      ),
      body: SafeArea(
        child: nearbyStores.isEmpty
            ? Center(child: Text('No nearby stores found.'))
            : ListView.builder(
                itemCount: nearbyStores.length,
                itemBuilder: (context, index) {
                  var store = nearbyStores[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8.0),
                      leading: Image.network(
                        store['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(store['name']),
                      subtitle: Text(store['type']),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        // Handle store selection and order logic here
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirm Store Selection'),
                            content: Text('You selected ${store['name']}. Proceed to place the order?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Show the order placed message after selection
                                  Navigator.of(context).pop(); // Close the confirmation dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Order Placed'),
                                      content: Text('Your order for the ingredients has been placed successfully!'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the order placed dialog
                                            Navigator.of(context).pop(); // Close store selection page
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text('Confirm'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
