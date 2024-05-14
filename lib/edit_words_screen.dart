import 'package:flutter/material.dart';
import 'database_helper.dart';

class EditWordsScreen extends StatefulWidget {
  final String initialSearch;
  EditWordsScreen({this.initialSearch = ""});

  @override
  _EditWordsScreenState createState() => _EditWordsScreenState();
}

class _EditWordsScreenState extends State<EditWordsScreen> {
  List<Map<String, dynamic>> words = [];
  List<Map<String, dynamic>> filteredWords = [];
  TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    //Position to the provided filter, if any
    editingController = TextEditingController(text: widget.initialSearch);
    _loadWords();
  }

  void _loadWords() async {
    var dbHelper = DatabaseHelper.instance;
    var snapshots = await dbHelper.queryAllRows();
    setState(() {
      words = snapshots.map((snapshot) {
        // Create a new map from the snapshot's value and include the 'id'
        var wordMap = Map<String, dynamic>.from(snapshot.value as Map<String, dynamic>);
        wordMap['id'] = snapshot.key; // Assuming snapshot.key holds the ID
        return wordMap;
      }).toList();
      _filterWords(editingController.text); // Re-filter the words after loading
    });
  }


  void _updateWord(Map<String, dynamic> word) async {
    var dbHelper = DatabaseHelper.instance;
    await dbHelper.update(word);
    _loadWords();
  }

  void _toggleActive(int id, bool isActive) async {
    var dbHelper = DatabaseHelper.instance;
    await dbHelper.toggleWordActive(id, !isActive);
    _loadWords();
  }

  void _deleteWord(int id) async {
    var dbHelper = DatabaseHelper.instance;
    await dbHelper.delete(id);
    _loadWords();
  }

  void _filterWords(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredWords = words;
      });
    } else {
      setState(() {
        filteredWords = query.isEmpty ? words : words.where((word) {
          return word['mandarin'].toLowerCase().contains(query.toLowerCase()) ||
              word['pinyin'].toLowerCase().contains(query.toLowerCase()) ||
              word['english'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _createWord(Map<String, dynamic> newWord) {
    var dbHelper = DatabaseHelper.instance;
    dbHelper.insert(newWord);
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Words"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterWords,
                    controller: editingController,
                    decoration: InputDecoration(
                      labelText: "Search",
                      hintText: "Filter by Mandarin, Pinyin, or English",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0))),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showEditDialog(null),  // Passing null to indicate a new word
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredWords.length,
              itemBuilder: (context, index) {
                var word = filteredWords[index];
                bool isActive = word[DatabaseHelper.columnIsActive] == 1;
                return ListTile(
                  title: Text(word[DatabaseHelper.columnMandarin]),
                  subtitle: Text("${word[DatabaseHelper.columnPinyin]} - ${word[DatabaseHelper.columnEnglish]}"),
                  trailing: Wrap(
                    spacing: 12, // space between two icons
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditDialog(word),
                      ),
                      IconButton(
                        icon: Icon(isActive ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => _toggleActive(word[DatabaseHelper.columnId], isActive),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteWord(word[DatabaseHelper.columnId]),
                      ),
                    ],
                  ),
                  tileColor: isActive ? Colors.white : Colors.grey[300],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic>? word) {
    bool isNew = word == null;
    TextEditingController mandarinController = TextEditingController(text: word?['mandarin'] ?? '');
    TextEditingController pinyinController = TextEditingController(text: word?['pinyin'] ?? '');
    TextEditingController englishController = TextEditingController(text: word?['english'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isNew ? 'Create New Word' : 'Edit Word'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: mandarinController,
                  decoration: InputDecoration(labelText: 'Mandarin'),
                ),
                TextField(
                  controller: pinyinController,
                  decoration: InputDecoration(labelText: 'Pinyin'),
                ),
                TextField(
                  controller: englishController,
                  decoration: InputDecoration(labelText: 'English'),
                ),
                if (!isNew)
                Row(
                  children: [
                    Text('Active:'),
                    Switch(
                      value: word[DatabaseHelper.columnIsActive] == 1,
                      onChanged: (bool value) {
                        Navigator.of(context).pop();
                        _toggleActive(word[DatabaseHelper.columnId], !value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                Map<String, dynamic> updatedWord = {
                  DatabaseHelper.columnMandarin: mandarinController.text,
                  DatabaseHelper.columnPinyin: pinyinController.text,
                  DatabaseHelper.columnEnglish: englishController.text,
                  DatabaseHelper.columnIsActive: word != null ? word[DatabaseHelper.columnIsActive] : 1,  // Use existing active status or default to active
                };

                if (!isNew) {
                  updatedWord[DatabaseHelper.columnId] = word![DatabaseHelper.columnId];
                }

                if (isNew) {
                  _createWord(updatedWord);
                } else {
                  _updateWord(updatedWord);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
