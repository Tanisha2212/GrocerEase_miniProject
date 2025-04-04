import 'package:flutter/material.dart';

import 'package:plswork/screens/widget/category.dart';
import 'package:plswork/screens/widget/header.dart';
import 'package:plswork/screens/widget/search.dart';
import 'package:plswork/screens/widget/search_cus.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, String>> _cuisines = [];

  @override
  void initState() {
    super.initState();
    _setCuisines(); // Set the cuisine names manually
  }

  // Manually set cuisine names and their corresponding asset images
  void _setCuisines() {
    _cuisines = [
      {'name': 'Italian', 'image': 'assets/itailian.png'},
      {'name': 'Mexican', 'image': 'assets/mexican.png'},
      {'name': 'Indian', 'image': 'assets/indian.png'},
      {'name': 'Chinese', 'image': 'assets/chinese.png'},
      {'name': 'Japanese', 'image': 'assets/japanese.png'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                const Header(),
                const Search(),
                _buildCuisineSlider(), // Updated slider with manual cuisine names and asset images
                const Category(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Slider to show cuisine images and navigate to RecipeCus screen
  Widget _buildCuisineSlider() {
    return _cuisines.isNotEmpty
        ? Container(
            height: 150, // Height of each rectangular box
            margin: const EdgeInsets.symmetric(vertical: 20.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cuisines.length,
              itemBuilder: (context, index) {
                final cuisine = _cuisines[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to RecipeCus screen with the selected cuisine name
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchCus(cuisine: cuisine['name']!),
                      ),
                    );
                  },
                  child: Container(
                    width: 220, // Width of each rectangular box
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: AssetImage(cuisine['image']!), // Use asset images
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cuisine['name']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}