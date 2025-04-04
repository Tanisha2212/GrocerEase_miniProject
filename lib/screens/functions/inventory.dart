import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class Inventory extends StatefulWidget {
  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  File? _image;
  String? _expiryDate;
  bool _isLoading = false;

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _manualExpiryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, String>> _inventoryList = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
        _isLoading = true;
      });

      String? recognizedDate = await recognizeExpiryDate(image.path);

      setState(() {
        _expiryDate = recognizedDate ?? "No expiry date found";
        _isLoading = false;
      });

      // Ask for item name after date recognition
      if (_expiryDate != null && _expiryDate != "No expiry date found") {
        await _promptItemName();
      }
    }
  }

  Future<String?> recognizeExpiryDate(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);

    List<DateTime> dates = [];

    // Extended regex pattern to recognize multiple date formats
    RegExp dateRegEx = RegExp(
        r'(\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2}|\d{2}/\d{4}|\d{4}/\d{2}|\d{2}-\d{4}|\d{4}-\d{2}|[A-Za-z]+ \d{4})');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final match = dateRegEx.allMatches(line.text);
        for (var m in match) {
          String? dateStr = m.group(0);
          DateTime? parsedDate = _parseDate(dateStr!);
          if (parsedDate != null) {
            dates.add(parsedDate);
          }
        }
      }
    }

    // Sort dates and return the largest (expiry date)
    if (dates.isNotEmpty) {
      dates.sort((a, b) => a.compareTo(b));
      return DateFormat('dd/MM/yyyy').format(dates.last);
    }

    return null;
  }

  // Parse multiple date formats
  DateTime? _parseDate(String dateStr) {
    List<String> formats = [
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'MM-yyyy',
      'yyyy-MM',
      'MMMM yyyy' // Format for month name (e.g., January 2023)
    ];

    for (String format in formats) {
      try {
        DateFormat dateFormat = DateFormat(format);
        return dateFormat.parse(dateStr);
      } catch (e) {
        // Ignore and continue trying other formats
      }
    }
    return null;
  }

  // Prompt the user to enter the item name after expiry date detection
  Future<void> _promptItemName() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Product Name'),
          content: TextField(
            controller: _itemNameController,
            decoration: InputDecoration(
              labelText: 'Product Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                addScannedItem();
                Navigator.of(context).pop();
              },
              child: Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  void addManualItem() {
    setState(() {
      _inventoryList.add({
        "name": _itemNameController.text,
        "expiryDate": _manualExpiryController.text,
        "quantity": _quantityController.text,
      });
      _itemNameController.clear();
      _manualExpiryController.clear();
      _quantityController.clear();
    });
  }

  void addScannedItem() {
    setState(() {
      if (_expiryDate != null && _itemNameController.text.isNotEmpty) {
        _inventoryList.add({
          "name": _itemNameController.text,
          "expiryDate": _expiryDate!,
          "quantity": _quantityController.text,
        });
        _itemNameController.clear();
        _expiryDate = null;
        _quantityController.clear();
        _image = null;
      }
    });
  }

  void deleteItem(int index) {
    setState(() {
      _inventoryList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Expiry Date Tracker'),
        backgroundColor: Colors.greenAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Add New Inventory Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 20),

            // Manual Entry Form
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _manualExpiryController,
              decoration: InputDecoration(
                labelText: 'Expiry Date (MM/YYYY or DD/MM/YYYY)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: addManualItem,
              child: Text(
                'Add Item Manually',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
            ),
            SizedBox(height: 20),

            // Image Section
            if (_image != null)
              Column(
                children: [
                  Image.file(
                    _image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            if (_isLoading) CircularProgressIndicator(),
            if (_expiryDate != null && !_isLoading)
              Column(
                children: [
                  Text(
                    'Detected Expiry Date: $_expiryDate',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: addScannedItem,
                    child: Text(
                      'Add Scanned Item',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),

            // Scan Button
            ElevatedButton(
              onPressed: pickImage,
              child: Text(
                'Scan Product for Expiry Date',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),

            SizedBox(height: 20),

            // Inventory List in Table Form
            Text(
              'Inventory List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: _inventoryList.isEmpty
                    ? Center(
                        child: Text(
                          'No items in inventory.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : DataTable(
                        columns: [
                          DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _inventoryList
                            .asMap()
                            .entries
                            .map(
                              (entry) => DataRow(
                                cells: [
                                  DataCell(Text(entry.value["name"] ?? "")),
                                  DataCell(Text(entry.value["expiryDate"] ?? "")),
                                  DataCell(Text(entry.value["quantity"] ?? "")),
                                  DataCell(
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteItem(entry.key),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}