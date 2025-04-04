import 'package:flutter/material.dart';
import 'search_cus.dart'; // Import your other page

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();

  // Method to navigate to SearchCus and pass the input or selected cuisine
  void _searchCuisine() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchCus(cuisine: query), // Pass input
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Stack(
        children: [
          TextField(
            controller: _controller,
            cursorColor: Colors.black12,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  width: 0,
                  style: BorderStyle.none,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              prefixIcon: const Icon(
                Icons.search_outlined,
                color: Color.fromARGB(255, 46, 199, 44),
                size: 30,
              ),
              hintText: 'Search Cuisine',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            onSubmitted: (_) => _searchCuisine(), // Search on Enter key
          ),
          Positioned(
            bottom: 6,
            right: 12,
            child: GestureDetector(
              onTap: _searchCuisine, // Search on mic icon tap
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.lightGreenAccent,
                ),
                child: const Icon(
                  Icons.mic_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
