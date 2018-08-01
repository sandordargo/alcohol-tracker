import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/main.dart';
import 'package:myapp/SignInContainer.dart';

import 'dart:convert';

class ImportV2 extends StatefulWidget {
  final BuildContext _scaffoldContext;

  ImportV2(this._scaffoldContext);

  State createState() => new ImportV2State(this._scaffoldContext);
}

class ImportV2State extends State<ImportV2> {
  final BuildContext _scaffoldContext;
  GoogleSignInAccount _currentUser;
  DataChangeNotification notifier = new DataChangeNotification();
  SignInContainer _signInContainer = new SignInContainer();

  ImportV2State(this._scaffoldContext);

  @override
  void initState() {
    super.initState();
    _currentUser = _signInContainer.getCurrentUser();
    _signInContainer.listen((account) {
      _currentUser = _signInContainer.getCurrentUser();
      if (this.mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildBody() {
    if (_currentUser != null) {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new ListTile(
            leading: new GoogleUserCircleAvatar(
              identity: _currentUser,
            ),
            title: new Text(_currentUser.displayName),
            subtitle: new Text(_currentUser.email),
          ),
          const Text("Signed in successfully."),
          const Text(
            "Importing the data will completely replace your current database.",
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 20.0),
            textAlign: TextAlign.center,
          ),
          new RaisedButton(
            child: const Text('Import data'),
            onPressed: () {
              Navigator.pop(context);
              _handleImport();
            },
          ),
        ],
      );
    } else {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text(
              "You are not currently signed in. In order to import data from your Google Drive, you have to sign in."),
          new RaisedButton(
            child: const Text('Sign in'),
            onPressed: _signInContainer.handleSignIn,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Import data'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }

  _handleImport() async {
    List<String> csvEntries = await _fetchData();
    _importData(csvEntries);
    if (_scaffoldContext != null) {
      _showSnackbar(csvEntries);
      notifyParentAboutImport();
    }
  }

  void notifyParentAboutImport() {
    notifier.dispatch(_scaffoldContext);
  }

  void _importData(List<String> csvEntries) {
    if (csvEntries.isNotEmpty) {
      List<Drink> drinks = _extractDrinksFromData(csvEntries);
      DrinkDatabase.get().deleteAll();
      _insertDrinks(drinks);
    }
  }

  void _showSnackbar(List<String> csvEntries) {
    Text content = new Text(csvEntries.isNotEmpty
        ? 'Data import finished successfully'
        : "Data import failed");
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(content: content));
  }

  List<Drink> _extractDrinksFromData(List<String> csvEntries) {
    List<Drink> drinks = new List();
    removeHeaders(csvEntries);
    for (var line in csvEntries) {
      var fields = line.split(',');
      if (_isLineFilled(fields)) {
        drinks.add(new Drink(
            name: fields[1],
            volume: (int.parse(fields[2])),
            strength: double.parse(fields[3]),
            unit: double.parse(fields[4]),
            consumptionDate:
                _extractConsumptionDateAsEpochFromString(fields[0])));
      }
    }
    return drinks;
  }

  int _extractConsumptionDateAsEpochFromString(String dateString) {
    var dateFields = dateString.split("-");
    return new DateTime(int.parse(dateFields[0]), int.parse(dateFields[1]),
            int.parse(dateFields[2]))
        .millisecondsSinceEpoch;
  }

  bool _isLineFilled(List<String> fields) =>
      fields[1].trimLeft() != "-" && fields[1].isNotEmpty;

  void _insertDrinks(List<Drink> drinks) {
    for (var drink in drinks) {
      DrinkDatabase.get().insertDrink(drink);
    }
  }

  void removeHeaders(List<String> csvEntries) {
    csvEntries.removeAt(0);
  }

  Future<List<String>> _fetchData() async {
    var fileId = await getFileId();
    final String url =
        'https://www.googleapis.com/drive/v3/files/$fileId/export?mimeType=text/csv';
    final http.Response response = await http.get(url, headers: await _signInContainer.getCurrentUser().authHeaders);
    if (response.statusCode != 200) {
      return new List<String>();
    }
    var csvUnformattedContent = response.body;
    var csvEntries = csvUnformattedContent.split("\n");
    return csvEntries;
  }

  Future<String> getFileId() async {
    final http.Response response = await http.get(
        'https://www.googleapis.com/drive/v3/files?q=name%3D%27AlcoholTrackerData.csv%27',
        headers: await _signInContainer.getCurrentUser().authHeaders);
    print("bod");
    print(response.body);
    final Map<String, dynamic> data = json.decode(response.body);
    return _pickFileId(data);
  }

  String _pickFileId(Map<String, dynamic> data) {
    final List<dynamic> files = data['files'];
    final Map<String, dynamic> fileData = files?.firstWhere(
      (dynamic contact) =>
          contact['mimeType'] == "application/vnd.google-apps.spreadsheet",
      orElse: () => null,
    );
    return fileData != null ? fileData["id"] : null;
  }
}
