import 'dart:async';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Detect if running on the web


class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;
  static final store = intMapStoreFactory.store('words_table');

  static final columnId = 'id';
  static final columnMandarin = 'mandarin';
  static final columnPinyin = 'pinyin';
  static final columnEnglish = 'english';
  static final columnIsActive = 'isActive';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();
  static DatabaseHelper get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
    }
    return _database!;
  }


  Future<Database> _initDatabase() async {
    try {
      DatabaseFactory dbFactory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
      var dir = kIsWeb ? null : await path_provider.getApplicationDocumentsDirectory();
      var dbPath = kIsWeb ? _databaseName : join(dir!.path, _databaseName);
      var db = await dbFactory.openDatabase(dbPath);
      _database = db;
      return db;
    } catch (e) {
      print("Failed to initialize the database: $e");
      rethrow; // To understand what's happening
    }
  }


  Future<void> insert(Map<String, dynamic> rowData) async {
    try {
      var dbClient = await database;
      // Make sure rowData contains all required fields and none of them are null
      if (rowData[columnMandarin] == null || rowData[columnPinyin] == null || rowData[columnEnglish] == null) {
        throw Exception("Mandatory fields must not be null");
      }
      await store.add(dbClient, rowData);
      print('row $rowData inserted');
    } catch (e) {
      print('Failed to insert row: $e');
    throw Exception("Failed to insert");; // Rethrow the exception after logging it or handling it
    }
    print('inserted $rowData');
  }


  Future<List<RecordSnapshot<int, Map<String, dynamic>>>> queryAllRows() async {
    var dbClient = await database;
    return await store.find(dbClient);
  }

  Future<int> update(Map<String, dynamic> row) async {
    var dbClient = await database;
    final finder = Finder(filter: Filter.byKey(row[columnId]));
    return await store.update(dbClient, row, finder: finder);
  }

  Future<int> delete(int id) async {
    var dbClient = await database;
    final finder = Finder(filter: Filter.byKey(id));
    return await store.delete(dbClient, finder: finder);
  }

  Future<void> toggleWordActive(int id, bool isActive) async {
    var dbClient = await database;
    final finder = Finder(filter: Filter.byKey(id));
    await store.update(dbClient, {columnIsActive: isActive ? 1 : 0}, finder: finder);
  }

  Future<void> clearTable() async {
    var dbClient = await database;
    await store.delete(dbClient);
    print ('cleared database');
  }

  Future<bool> isDatabaseEmpty() async {
    var dbClient = await database;
    var records = await store.find(dbClient);
    return records.isEmpty;
  }
}
