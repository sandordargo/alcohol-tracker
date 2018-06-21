import 'package:flutter/material.dart';
import 'dart:async';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';

import 'dart:convert';
import 'dart:io';

class Import extends StatefulWidget {
  BuildContext _scaffoldContext;

  Import(_scaffoldContext) {
    this._scaffoldContext = _scaffoldContext;
  }

  @override
  _ImportState createState() => new _ImportState(_scaffoldContext);
}

class _ImportState extends State<Import> {
  BuildContext _scaffoldContext;

  _ImportState(_scaffoldContext) {
    this._scaffoldContext = _scaffoldContext;
  }

  Widget _buildBody() {
    return new Container(
        margin: new EdgeInsets.symmetric(horizontal: 5.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            const Text(
              "Importing the data will completely replace your current database.",
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
            new RaisedButton(
              child: const Text('Import data'),
              onPressed: () {
                Navigator.pop(context);
                importData();
                Scaffold.of(_scaffoldContext).showSnackBar(
                    new SnackBar(content: new Text('Data import finished')));
              },
            ),
          ],
        ));
  }

  importData() async {
    List<String> csvEntries = await fetchData();
    List<Drink> drinks = new List();
    removeHeaders(csvEntries);
    for (var line in csvEntries) {
      var fields = line.split(',');
      if (fields[1].trimLeft() != "-" && fields[1].isNotEmpty) {
        print(fields);
        print("a" + fields[1] + "a");
        var dateFields = fields[0].split("/");
        drinks.add(new Drink(
            name: fields[1],
            volume: (double.parse(fields[2]) * 1000).round(),
            strength: double.parse(fields[3]),
            unit: double.parse(fields[4]),
            consumptionDate: new DateTime(int.parse(dateFields[0]),
                    int.parse(dateFields[1]), int.parse(dateFields[2]))
                .millisecondsSinceEpoch));
      }
    }
    print(drinks);
    DrinkDatabase.get().deleteAll();
    for (var drink in drinks) {
      DrinkDatabase.get().insertDrink(drink);
    }
  }

  void removeHeaders(List<String> csvEntries) {
    csvEntries.removeAt(0);
  }

  Future<List<String>> fetchData() async {
    final String url =
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vTfgFcbX95lQiX2aGBlVJLKeLR4IMPPK-AczuYjkOp22PN8CAb2WgUNDZ-iWT-I95Vff7aaZq5qtu1K/pub?gid=0&single=true&output=csv';
    var httpClient = new HttpClient();
    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        var csvUnformattedContent =
            await response.transform(const Utf8Decoder()).join();
        var csvEntries = csvUnformattedContent.split("\n");
        return csvEntries;
      } else {
        print("Failed http call.");
        return new List<String>();
      }
    } catch (exception) {
      print(exception.toString());
      return new List<String>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Import consumption data'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
