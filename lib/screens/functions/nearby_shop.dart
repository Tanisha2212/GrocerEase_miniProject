import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:plswork/screens/widget/order_page.dart';

void main() {
  runApp(MaterialApp(
    home: NearbyStoresScreen(),
  ));
}

class NearbyStoresScreen extends StatefulWidget {
  @override
  _NearbyStoresScreenState createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen> {
  List<Map<String, dynamic>> nearbyStores = [];
  bool isLoading = true;
  final TextEditingController _ingredientsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await _fetchNearbyStores(position.latitude, position.longitude);
    } catch (e) {
      print('Error fetching location: $e');
      nearbyStores = [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyStores(double latitude, double longitude) async {
    final String apiKey =
        'fsq3hij2i1l+zuoTuhXO3F181P/WbRuxlBmdsWPGgWWwBxw='; // Your Foursquare API key
    final String apiUrl =
        'https://api.foursquare.com/v3/places/search?ll=$latitude,$longitude&radius=15000&categories=13029,13037'; // Supermarkets and Grocery Stores

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
            return {
              'name': store['name'] ?? 'Unknown Store',
              'type':
                  store['categories'] != null && store['categories'].isNotEmpty
                      ? store['categories'][0]['name']
                      : 'Unknown Type',
              'latitude': store['geocodes']['main']['latitude'],
              'longitude': store['geocodes']['main']['longitude'],
              'photos': store['photos'], // Keep photos for later use
              'id': store['id'] // Store ID to pass to the order page
            };
          }).toList();
        });
      } else {
        print('Failed to fetch nearby stores.');
      }
    } catch (e) {
      print('Error fetching stores: $e');
    }
  }

  void _navigateToOrderPage(String storeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPage(
            storeId: storeId,
            ingredients: _ingredientsController.text.split(',')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Stores'),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : nearbyStores.isEmpty
                ? Center(child: Text('No stores found nearby'))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _ingredientsController,
                          decoration: InputDecoration(
                            labelText: 'Enter ingredients (comma-separated)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: nearbyStores.length,
                          itemBuilder: (context, index) {
                            var store = nearbyStores[index];
                            String imageUrl = store['photos'] != null &&
                                    store['photos'].isNotEmpty
                                ? '${store['photos'][0]['prefix']}300x300${store['photos'][0]['suffix']}'
                                : ''; // No URL, fallback to icon

                            return Card(
                              margin: EdgeInsets.all(8.0),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(8.0),
                                leading: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Show the shopping cart icon if the image fails to load
                                          return Icon(
                                            Icons.shopping_cart,
                                            size: 50,
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.shopping_cart, // Fallback icon
                                        size: 50,
                                      ),
                                title: Text(store['name']),
                                subtitle: Text(store['type']),
                                trailing: Icon(Icons.arrow_forward),
                                onTap: () {
                                  _navigateToOrderPage(
                                      store['id']); // Navigate to order page
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
