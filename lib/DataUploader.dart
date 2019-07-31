import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:date_format/date_format.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/SignInContainer.dart';
import 'package:myapp/prefs.dart';

class DataUploader {
  final List<Drink> data;
  SignInContainer _signInContainer = new SignInContainer();
  static bool  exporting = false;
  final BuildContext _scaffoldContext;

  DataUploader(this.data, this._scaffoldContext);

  void upload() {
    if (_signInContainer.getCurrentUser() != null) {
      if (!DataUploader.exporting) {
        DataUploader.exporting = true;
        Prefs.setBool("sync_needed", false);
        Prefs.setInt("last_sync", DateTime.now().millisecondsSinceEpoch);
        _exportData().then((status) {
          DataUploader.exporting = false;
          _showSnackbar(new Text(status == 200
              ? 'Data upload finished successfully'
              : "Data upload failed"));
        });
      }
    }
    else {
      _showSnackbar(Text("Login please for synching (NULL user)"));
    }
  }

  void _showSnackbar(Text content) {
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(content: content));
  }


  Future<int> _exportData() async {
    if (await _signInContainer.isSignedIn() == false) {
      _showSnackbar(Text("Login please for synching (not signed in)"));
      return 403;
    }

    var fileId = await getFileId();
    if (fileId == null) {
      fileId = await _createFile();
    }

    return _upload(fileId);
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
      _showSnackbar(Text("Data upload failed"));
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

  Future<int> _upload(String fileId) async {
    if (fileId == null) {
      _showSnackbar(Text("Upload failed"));
      return 500;
    }
    final http.Response response = await http.patch(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
        headers: await _signInContainer.getCurrentUser().authHeaders,
        body: getDataToUpload());
    print("upload status ${response.statusCode}");
    return response.statusCode;
  }
}
