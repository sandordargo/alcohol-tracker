import 'dart:io';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:advanced_share/advanced_share.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';

import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:date_format/date_format.dart';


// Define a Custom Form Widget
class ExportData extends StatefulWidget {
  List<Drink> data;
  ExportData(data) {
    this.data = data;
    print("dataconsbeg");
    print(this.data);
    print("dataconsend");
  }

  @override
  _ExportDataState createState() => new _ExportDataState(data);
}

class _ExportDataState extends State<ExportData>{

  List<Drink> data;
  _ExportDataState(data) {
    this.data = data;
    print("statedataconsbeg");
    print(this.data);
    print("statedataconsend");
  }
  final emailController = new TextEditingController();

  var encodedData;
  bool done = false;

  @override
  void initState() {
    super.initState();
    getSavedFileB64().then((result) {
      setState(() {
        encodedData = result;
        done = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
//    print("path " + DrinkDatabase.get().getDatabasePath());
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Export data and send email"),
      ),
      body: new Center(
        child: new Column(children: [
          new Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: new TextField(
              controller: emailController,
              onChanged: (text) {
                print("First text field: $text");
              },
              keyboardType: TextInputType.text,
              decoration: new InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Please enter the e-amil address you want to send the data'),
            ),
          ),
          new RaisedButton(
            onPressed: () {

//              Navigator.pop(context);
              AdvancedShare.gmail(
                  msg: encodedData,
                  subject: "Share with Advanced Share",
                  url: encodedData
              ).then((response){
                print(response);
              });

//              return showDialog(
//                context: context,
//                builder: (context) {
//                  return new AlertDialog(
//                    // Retrieve the text the user has typed in using our
//                    // TextEditingController
//                    content: new Text("Email sent to ${emailController.text}"),
//                  );
//                },
//              );
            },
            child: new Text(done.toString()),
          )
        ]),
      ),
    );
  }
  Future<String> getSavedFileB64() async {
    Directory dir = await getTemporaryDirectory();
    var num = Random().nextInt(9999999);
    File file = new File(dir.path + "/mydata-$num.csv");
    file.createSync();
    String contents = "";
    print("ll");
    print(data);
    for (var drink in data) {
      var dateString = formatDate(
          new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate),
          [yyyy, '-', mm, '-', dd
          ]);
      var line = dateString + "," + drink.name + "," + drink.volume.toString() + "," + drink.strength.toString() + "," + drink.unit.toString() + "\n";
      contents += line;
    }

    file.writeAsStringSync(contents);

    File newFile = file.copySync((await getApplicationDocumentsDirectory()).path+"/new-$num.csv");
    var base64 = base64Encode(newFile.readAsBytesSync());
    print(newFile);
    return "data:text/csv;base64,"+base64;
//  return base64;
  }
}
