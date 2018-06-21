import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'dart:convert' show json;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


GoogleSignIn _googleSignIn = new GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);


// Define a Custom Form Widget
class Import extends StatefulWidget {
  @override
  _ImportState createState() => new _ImportState();
}

class _ImportState extends State<Import>{
  GoogleSignInAccount _currentUser;
  String _contactText;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetContact();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<Null> _handleGetContact() async {
    setState(() {
      _contactText = "Loading contact info...";
    });
    final http.Response response = await http.get(
      'https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names',
      headers: await _currentUser.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        _contactText = "People API gave a ${response.statusCode} "
            "response. Check logs for details.";
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final String namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = "I see you know $namedContact!";
      } else {
        _contactText = "No contacts to display.";
      }
    });
  }

  String _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic> connections = data['connections'];
    final Map<String, dynamic> contact = connections?.firstWhere(
          (dynamic contact) => contact['names'] != null,
      orElse: () => null,
    );
    if (contact != null) {
      final Map<String, dynamic> name = contact['names'].firstWhere(
            (dynamic name) => name['displayName'] != null,
        orElse: () => null,
      );
      if (name != null) {
        return name['displayName'];
      }
    }
    return null;
  }

  Future<Null> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<Null> _handleSignOut() async {
    _googleSignIn.disconnect();
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
          new Text(_contactText),
          new RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
          new RaisedButton(
            child: const Text('REFRESH'),
            onPressed: _handleGetContact,
          ),
        ],
      );
    } else {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          new RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
          new RaisedButton(
            child: const Text('Load data'),
            onPressed: getMovies,
          ),
        ],
      );
    }
  }

  getMovies() async {
    final String url = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTfgFcbX95lQiX2aGBlVJLKeLR4IMPPK-AczuYjkOp22PN8CAb2WgUNDZ-iWT-I95Vff7aaZq5qtu1K/pub?gid=0&single=true&output=csv';
    var httpClient = new HttpClient();
    try {
      // Make the call
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
//        var json = await response.transform(UTF8.decoder).join();
        var what = await response.transform(const Utf8Decoder()).join();
        var lines = what.split("\n");
        List<Drink> drinks = new List();
        lines.removeAt(0);
        for (var line in lines) {
          print("buuub " +  line);
          var fields = line.split(',');
          if (fields[1].trimLeft() != "-" && fields[1].isNotEmpty) {
            print(fields);
            print("a" + fields[1] + "a");
            var dateFields = fields[0].split("/");
            drinks.add(new Drink(name: fields[1],
                volume: (double.parse(fields[2])*1000).round(),
                strength: double.parse(fields[3]),
                unit: double.parse(fields[4]),
                consumptionDate: new DateTime(int.parse(dateFields[0]),
                    int.parse(dateFields[1]),
                    int.parse(dateFields[2])).millisecondsSinceEpoch));

          }

        }
        print(drinks);
        DrinkDatabase.get().deleteAll();
        for (var drink in drinks) {
          DrinkDatabase.get().insertDrink(drink);
        }
      } else {
        print("Failed http call.");
      }
    } catch (exception) {
      print(exception.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Google Sign In'),
        ),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }

}
