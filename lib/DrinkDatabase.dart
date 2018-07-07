import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myapp/Drink.dart';

class DrinkDatabase {
  static final DrinkDatabase _drinkDatabase = new DrinkDatabase._internal();

  final String tableName = "DrinksConsumed";

  static String path;
  Database db;

  bool didInit = false;

  static DrinkDatabase get() {
    return _drinkDatabase;
  }

  DrinkDatabase._internal();

  /// Use this method to access the database, because initialization of the database (it has to go through the method channel)
  Future<Database> _getDb() async {
    if (!didInit) await _init();
    return db;
  }

  Future init() async {
    return await _init();
  }

  Future _init() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = join(documentsDirectory.path, "demo.db");
    DrinkDatabase.path = path;
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute("CREATE TABLE $tableName ("
          "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
          "DRINK TEXT,"
          "VOLUME INT,"
          "STRENGTH REAL,"
          "UNITS REAL,"
          "CONSUMPTION_DATE INTEGER,"
          "REMARK TEXT"
          ")");
    });
    didInit = true;
  }

  /// Get a book by its id, if there is not entry for that ID, returns null.
  Future<Drink> getBook(int id) async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM $tableName WHERE ID = "$id"');
    if (result.length == 0) return null;
    return new Drink(
        name: null,
        volume: null,
        strength: null,
        unit: null,
        consumptionDate: null);
  }


  Future insertDrink(Drink drink) async {
    var db = await _getDb();
    await db.rawInsert(
        'INSERT INTO $tableName(DRINK, VOLUME, STRENGTH, UNITS, CONSUMPTION_DATE, REMARK)'
        ' VALUES (?, ?, ?, ?, ?, ?)',
        [
          drink.name,
          drink.volume,
          drink.strength,
          drink.unit,
          drink.consumptionDate,
          drink.remark
        ]);
  }

  Future<List<Drink>> getAllDrinks() async {
    var db = await _getDb();
    var result = await db
        .rawQuery('SELECT * FROM $tableName ORDER BY CONSUMPTION_DATE DESC');
    if (result.length == 0) return [];
    List<Drink> drinks = [];
    for (Map<String, dynamic> map in result) {
      drinks.add(new Drink(
          id: map["ID"],
          name: map["DRINK"],
          volume: map["VOLUME"],
          strength: map["STRENGTH"],
          unit: map["UNITS"],
          consumptionDate: map["CONSUMPTION_DATE"],
          remark: map["REMARK"]));
    }
    return drinks;
  }

  void deleteDrink(Drink drink) {
    db.delete(tableName, where: "ID = ?", whereArgs: [drink.id]);
  }

  void deleteAll() {
    db.delete(tableName);
  }

  Future updateDrink(Drink drink) async {
    var db = await _getDb();
    await db.rawUpdate(
        'UPDATE $tableName SET DRINK = ?, VOLUME = ?, STRENGTH = ?, UNITS = ?, CONSUMPTION_DATE = ?, REMARK = ?'
        ' WHERE ID = ?',
        [
          drink.name,
          drink.volume,
          drink.strength,
          drink.unit,
          drink.consumptionDate,
          drink.remark,
          drink.id
        ]);
  }

  Future upsertDrink(Drink drink) async {
    return drink.id == null ? insertDrink(drink) : updateDrink(drink);
  }

  Future close() async {
    var db = await _getDb();
    return db.close();
  }

  String getDatabasePath() {
    File file = new File(DrinkDatabase.path + ".txt");
    print(file.toString());
    file.writeAsStringSync("blablabla");
    file.createSync();
    print(file.existsSync());
    var bytes = UTF8.encode(file.readAsStringSync());
    var base64 = BASE64.encode(bytes);
    print(bytes);
    print(base64);

    return "data:text/plain;base64,"+ base64 ;
  }
}
