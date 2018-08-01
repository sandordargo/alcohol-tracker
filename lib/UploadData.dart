import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:date_format/date_format.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/SignInContainer.dart';

class UploadData extends StatefulWidget {
  final List<Drink> data;

  UploadData(this.data);

  State createState() => new UploadDataState(this.data);
}

class UploadDataState extends State<UploadData> {
  final List<Drink> data;
  GoogleSignInAccount _currentUser;
  String _contactText = "";
  SignInContainer _signInContainer = new SignInContainer();

  UploadDataState(this.data);

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
          getTitle(),
          const Text("Signed in successfully."),
          new Text(_contactText),
          new RaisedButton(
            child: const Text('UPLOAD AGAIN'),
            onPressed: () {
              Navigator.pop(context);
              _exportData();
            },
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
            onPressed: _signInContainer.handleSignIn,
          ),
        ],
      );
    }
  }

  Widget getTitle() {
    if (_currentUser == null) {
      return new ListTile(
        leading: getLead(),
        title: new Text("Sign in"),
        onTap: _signInContainer.handleSignIn,
      );
    }
    return new ListTile(
      leading: getLead(),
      title: new Text(_currentUser.displayName),
      subtitle: new Text(_currentUser.email),
    );
  }

  Widget getLead() {
    if (_currentUser == null) {
      return new CircleAvatar(child: new Text("?"));
    }
    return new GoogleUserCircleAvatar(
      identity: _currentUser,
    );
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

  Future<Null> _exportData() async {
    if (await _signInContainer.isSignedIn() == false) {
      print("cannot upload, sign out");
      return;
    }
    if (this.mounted) {
      setState(() {
        _contactText = "Uploading data to your Google Drive...";
      });
    }

    var fileId = await getFileId();

    if (fileId == null) {
      fileId = await _createFile();
    }
    _upload(fileId);
  }

  Future<String> _createFile() async {
    var myheaders = await _signInContainer.getCurrentUser().authHeaders;
    var mybody =
        "{\"name\": \"AlcoholTrackerData.csv\", \"mimeType\": \"application/vnd.google-apps.spreadsheet\"}";

    myheaders["Content-Type"] = "application/json; charset=UTF-8";

    final http.Response response = await http.post(
        'https://www.googleapis.com/drive/v3/files',
        headers: myheaders,
        body: mybody);

    if (response.statusCode != 200) {
      setState(() {
        _contactText = "Drive API gave a ${response.statusCode} "
            "response. Check logs for details.";
      });
      return null;
    }

    final Map<String, dynamic> data = json.decode(response.body);
    return data["id"];
  }

  String getDataToUpload() {
    String contents = "";
    String dateString = "";
    String line = "";
    for (var drink in data.reversed) {
      dateString = formatDate(
          new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate),
          [yyyy, '-', mm, '-', dd]);
      line = dateString +
          "," +
          drink.name +
          "," +
          drink.volume.toString() +
          "," +
          drink.strength.toString() +
          "," +
          drink.unit.toString() +
          "\n";
      contents += line;
    }
    return contents;
  }

  Future<String> getFileId() async {
    final http.Response response = await http.get(
        'https://www.googleapis.com/drive/v3/files?q=name%3D%27AlcoholTrackerData.csv%27',
        headers: await _signInContainer.getCurrentUser().authHeaders);
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

  void _upload(String fileId) async {
    if (fileId == null) {
      return;
    }
    final http.Response response = await http.patch(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
        headers: await _signInContainer.getCurrentUser().authHeaders,
        body: getDataToUpload());
    print(response.statusCode);
    print(response.body);
  }
}
