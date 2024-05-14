import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'dart:convert';
import 'qr_scan_screen.dart'; // Import QR scan screen

class LoadCsvScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onCsvLoaded;

  LoadCsvScreen({required this.onCsvLoaded});

  @override
  _LoadCsvScreenState createState() => _LoadCsvScreenState();
}

class _LoadCsvScreenState extends State<LoadCsvScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false; // State variable to track loading status
  bool _isClipboardLoading = false; //State variable for the clipboard loading process

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load CSV'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "This allows to load a list of words via a CSV file accessible via a URL OR in the clipboard. It will REPLACE the current list. The file should be tab-separated (tsv) with 3 columns, with no title, with the first column containing the Mandarin word, the second the Pinyin transcription, and the third the translation in English. You can also scan the URL via a QR Code. To build such a file, use Google Sheets, then go to File > Share > Publish to the web and pick CSV. Then use the URL obtained to load the list. Or copy your data from Google Sheets or Excel and load from clipboard",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'CSV URL',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () => _scanQRCode(),
                    ),
                    IconButton(
                      icon: Icon(Icons.paste),
                      onPressed: () => _loadCsvFromUrl(_controller.text),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _loadCsvFromUrl(_controller.text),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Load CSV from URL'),
                ),
              ),
              SizedBox(width: 10), // Spacing between buttons
              Expanded(
                child: ElevatedButton(
                  onPressed: _isClipboardLoading ? null : () => _loadCsvFromClipboard(),
                  child: _isClipboardLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Load from Clipboard'),
                ),
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  void _loadCsvFromClipboard() async {
    setState(() {
      _isClipboardLoading = true; // Indicate loading data
    });
    try {
      ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      String csvData = clipboardData?.text ?? '';
      if (csvData.isNotEmpty) {
        List<List<String>> csvList = parseCsvData(csvData);
        _showImportDialog(csvList);
      } else {
        throw Exception('No data in clipboard');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load data from clipboard. Error: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isClipboardLoading = false; // Reset loading indicator
      });
    }
  }

  void _loadCsvFromUrl(String url) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final csvData = utf8.decode(response.bodyBytes);
        List<List<String>> csvList = parseCsvData(csvData);
        _showImportDialog(csvList);
        if (!mounted) return;
      } else {
        throw Exception('Failed to download the CSV file.');
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load CSV. Please check the URL and try again. Error: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //Function to parse the csv data and turn it into a list
  List<List<String>> parseCsvData(String csvData, {String delimiter = '\t', String eol = '\n'}) {
    List<List<String>> csvList = [];

    // Split the data into lines
    List<String> lines = csvData.split(eol).where((line) => line.trim().isNotEmpty).toList();

    for (var line in lines) {
      // Split each line into columns based on the delimiter
      List<String> fields = line.split(delimiter);

      // Ensure each line has exactly 3 fields, adding empty fields if necessary
      while (fields.length < 3) {
        fields.add('');  // Add empty string for missing fields
      }

      // Trim fields to remove any extraneous whitespace
      fields = fields.map((field) => field.trim()).toList();

      // Add the processed fields to the main list
      csvList.add(fields);
    }

    return csvList;
  }

  // Function to show import dialog
  void _showImportDialog(List<List<String>> csvList) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Import'),
        content: Text('Do you want to REPLACE the current list or ADD to it? \n\nNumber of words: ${csvList.length}'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await _insertCsvDataIntoDatabase(csvList, clearExisting: true);
              Navigator.pop(ctx); // Close the dialog
              print('About to pop LoadCsvScreen');
              //await Future.delayed(Duration(seconds: 1)); // Simulate delay in operation
              Navigator.pop(context, true); // Pop LoadCsvScreen with a result indicating success
            },
            child: Text('Replace'),
          ),
          TextButton(
            onPressed: () async {
              await _insertCsvDataIntoDatabase(csvList, clearExisting: false);
              Navigator.pop(ctx); // Close the dialog
              print('About to pop LoadCsvScreen');
              //await Future.delayed(Duration(seconds: 1)); // Simulate delay in operation
              Navigator.pop(context, true); // Pop LoadCsvScreen with a result indicating success
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // Function to insert CSV data into database
  Future<void> _insertCsvDataIntoDatabase(List<List<String>> csvList, {bool clearExisting = false}) async {
    final dbHelper = DatabaseHelper.instance;
    if (clearExisting) await dbHelper.clearTable();
    for (var row in csvList) {
      // Ensure there are elements to process, even if they might be fewer than expected
      Map<String, dynamic> rowData = {
        DatabaseHelper.columnMandarin: row.length > 0 ? row[0]?.toString() ?? '' : '',
        DatabaseHelper.columnPinyin: row.length > 1 ? row[1]?.toString() ?? '' : '',
        DatabaseHelper.columnEnglish: row.length > 2 ? row[2]?.toString() ?? '' : '',
        DatabaseHelper.columnIsActive: 1
      };
      await dbHelper.insert(rowData);
    }
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanScreen(onUrlReceived: (url) {
          _controller.text = url;
          _loadCsvFromUrl(url);
        }),
      ),
    );
  }
}
