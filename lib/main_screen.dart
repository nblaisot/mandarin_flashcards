import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:csv/csv.dart';
import 'edit_words_screen.dart';
import 'load_csv_screen.dart';
import 'database_helper.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> _words = [];
  int currentIndex = 0;
  bool showMandarin = true;
  bool showPinyin = false;
  bool showEnglish = false;
  String defaultVisibleLanguage = 'Mandarin'; // Track the default visible language
  int totalWords = 0;
  int activeWords = 0;

  @override
  void initState() {
    super.initState();
    checkAndLoadDataFromCSV();
  }

  //Load from local file if empty
  void checkAndLoadDataFromCSV() async {
    print('checkAndLoadDataFromCSV');
    var dbHelper = DatabaseHelper.instance;
    bool isEmpty = await dbHelper.isDatabaseEmpty();
    if (isEmpty) {
      loadWordsFromCSV();
    } else {
      loadWordsFromDatabase();
    }
  }

  void loadWordsFromDatabase() async {
    print('loadWordsFromDatabase, reloading the words from the database');
    var dbHelper = DatabaseHelper.instance;
    var records = await dbHelper.queryAllRows();
    setState(() {
      // Create a new list of words, copying each map and adding the 'id'
      _words = records.map((record) {
        var wordMap = Map<String, dynamic>.from(record.value as Map<String, dynamic>);
        wordMap['id'] = record.key;  // Safely adding 'id' to the new map
        return wordMap;
      }).where((word) => word['isActive'] == 1).toList();
      totalWords = records.length;
      activeWords = _words.length;
      print('_words has been refreshed from the database, now $activeWords active words');
      pickRandomWord();  // Call it here to pick a random word after loading
    });
  }


  void loadWordsFromCSV() async {
    //Actually replacing with just 1 fake entry
      await DatabaseHelper.instance.insert({
        'mandarin': '欢迎',
        'pinyin': 'huān yíng',
        'english': 'Welcome',
        'isActive': 1
      });
    loadWordsFromDatabase();
  }


  void pickRandomWord() {
    print('pickRandomWord');
    if (_words.isNotEmpty) {
      int newRandomIndex = Random().nextInt(_words.length);  // Directly use _words which contains only active words
      setState(() {
        currentIndex = newRandomIndex;
        showMandarin = defaultVisibleLanguage == 'Mandarin';
        showPinyin = defaultVisibleLanguage == 'Pinyin';
        showEnglish = defaultVisibleLanguage == 'English';
      });
    } else {
      print('No active words to display');
      setState(() {
        currentIndex = -1;
      });
    }
  }

  /* Actually provided in database_helpervoid toggleWordActive() async {
    var dbHelper = DatabaseHelper.instance;
    Map<String, dynamic> currentWord = _words[currentIndex];
    bool currentActive = currentWord['isActive'] == 1; // Assuming isActive is stored as int
    await dbHelper.toggleWordActive(currentWord['id'], !currentActive);
    loadWordsFromDatabase();
  }*/

  void handleMenuAction(String value) {
    if (value == 'edit') {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditWordsScreen())
      ).then((_) {
        loadWordsFromDatabase();  // Always refresh after returning from edit screen
      });
    } else if (value == 'load') {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoadCsvScreen(onCsvLoaded: (csvList) {
            // Optional: Handle the CSV load result here if needed.
          }))
      ).then((result) {
        // Check if the result is true, indicating that the data was loaded successfully
        if (result == true) {
          loadWordsFromDatabase();  // Always refresh after returning from load CSV screen
        }
      });
    } else if (value == 'copy_csv') {
      generateCsvFile().then((csvData) {
        copyToClipboard(csvData);
      });
      // No navigation here, so no need for additional action.
    }
  }


  void copyToClipboard(String csvData) {
    Clipboard.setData(ClipboardData(text: csvData)).then((_) {
      // Optionally, show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV data copied to clipboard!'))
      );
    });
  }

  Future<String> generateCsvFile() async {
    var dbHelper = DatabaseHelper.instance;
    var records = await dbHelper.queryAllRows();

    List<List<dynamic>> rows = [
      ["Mandarin", "Pinyin", "English", "IsActive"]  // Header row
    ];

    for (var record in records) {
      var map = record.value as Map<String, dynamic>; // Extract the map from the snapshot
      List<dynamic> row = [
        map['mandarin'].replaceAll('\r', '').replaceAll('\n', ' '),
        map['pinyin'].replaceAll('\r', '').replaceAll('\n', ' '),
        map['english'].replaceAll('\r', '').replaceAll('\n', ' '),
        map['isActive'].toString()
      ];
      rows.add(row);
    }

    String csv = const ListToCsvConverter(fieldDelimiter: '\t', eol: '\n').convert(rows);
    return csv;
  }

  void toggleWordActive() async {
    if (_words.isNotEmpty && currentIndex >= 0) {
      var dbHelper = DatabaseHelper.instance;
      Map<String, dynamic> currentWord = _words[currentIndex];
      print('currentIndex: $currentIndex, currentWord: $currentWord');
      bool currentActive = currentWord['isActive'] == 1;
      await dbHelper.toggleWordActive(currentWord['id'], !currentActive);
      loadWordsFromDatabase();  // Refresh the list after toggling
    }
  }


  @override
  Widget build(BuildContext context) {
    print("Building MainScreen with totalWords: $totalWords, activeWords: $activeWords");
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mandarin Flashcards'),
            Text(
              'Words: $activeWords / $totalWords',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.centerLeft,
            height: 48.0,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: defaultVisibleLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    defaultVisibleLanguage = newValue!;
                    // Update visibility based on the new default language
                    showMandarin = newValue == 'Mandarin';
                    showPinyin = newValue == 'Pinyin';
                    showEnglish = newValue == 'English';
                  });
                },
                items: <String>['Mandarin', 'Pinyin', 'English']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: handleMenuAction,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit List'),
              ),
              const PopupMenuItem<String>(
                value: 'load',
                child: Text('Load CSV from Web'),
              ),
              const PopupMenuItem<String>(
                value: 'copy_csv',
                child: Text('Copy DB to Clipboard as tsv'),
              ),
            ],
          ),
        ],
      ),
      body: _words.isEmpty || _words.every((word) => word[DatabaseHelper.columnIsActive] != 1)
          ? Center(child: Text('No active words available'))
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildWordTile('Mandarin', _words[currentIndex][DatabaseHelper.columnMandarin], showMandarin, () => setState(() => showMandarin = !showMandarin)),
            buildWordTile('Pinyin', _words[currentIndex][DatabaseHelper.columnPinyin], showPinyin, () => setState(() => showPinyin = !showPinyin)),
            buildWordTile('English', _words[currentIndex][DatabaseHelper.columnEnglish], showEnglish, () => setState(() => showEnglish = !showEnglish)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed:() {
                    Navigator.push(context,
                      MaterialPageRoute(builder:
                          (context) => EditWordsScreen(initialSearch: _words[currentIndex][DatabaseHelper.columnMandarin]),
                      ),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: toggleWordActive,
                  child: Text('Hide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,  // Correctly using backgroundColor
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: pickRandomWord,
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFC107),  // Correctly using backgroundColor
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget buildWordTile(String label, String word, bool isVisible, VoidCallback toggleVisibility) {
    print('Building wordTile');
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        subtitle: Container(
          height: 48, // Fixed height for the subtitle container
          alignment: Alignment.centerLeft,
          child: isVisible ? FittedBox(
              fit: BoxFit.scaleDown, // Ensures the text does not overflow and scales down
              child: Text(word, style: TextStyle(fontSize: 24, color: Colors.black))
          ) : null,
        ),
        onTap: toggleVisibility,
        tileColor: isVisible ? Color(0xFFFFE083) : Colors.grey[200],//Main yellow is #FFC107
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
