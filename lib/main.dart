import 'package:flutter/material.dart';
import 'package:myapp/UpsertConsumption.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/ImportV2.dart';
import 'dart:async';
import 'package:myapp/UploadData.dart';
import 'package:myapp/MainStats.dart';
import 'package:myapp/MyDrawer.dart';
import 'package:date_format/date_format.dart';

void main() => runApp(new MyApp());

class DataChangeNotification extends Notification {}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Alcohol Consumption Tracker',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Last 30 Days'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BuildContext _scaffoldContext;
  List<Drink> data;

  void addConsumption() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new UpsertConsumption()),
    );
  }

  void import() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new ImportV2(_scaffoldContext)),
    );
  }

  void exportData() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new UploadData(this.data)),
    );
  }

  Future<List<Drink>> getFromDb() async {
    return await DrinkDatabase.get().getDrinksFromLastMonth();
  }

  List<Widget> getWidgetList(List<Drink> drinks) {
    List<Widget> widgets = new List<Widget>();
    for (var drink in drinks) {
      widgets.add(new ListTile(
        leading: new Text('${formatDate(
            new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate),
            [yyyy, '-', mm, '-', dd
            ])}'),
        trailing: new Container(
          child: new IconButton(
            icon: new Icon(Icons.delete),
            onPressed: () {
              AlertDialog dialog = new AlertDialog(
                content: new Text(
                  "Do you really want to delete this drink?",
                  style: new TextStyle(fontSize: 30.0),
                ),
                actions: <Widget>[
                  new FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteConsumption(drink);
                      },
                      child: new Text('Yes')),
                  new FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: new Text('No')),
                ],
              );

              showDialog(context: context, builder: (context) => dialog);
            },
          ),
//              margin: const EdgeInsets.symmetric(horizontal: 0.5)
        ),
        title: new Text(
          '${drink.name[0].toUpperCase() + drink.name.substring(1)}, ${drink
              .unit.toStringAsPrecision(2)} units of alcohol',
          style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0),
        ),
        subtitle:
            new Text('Volume: ${drink.volume}, strength: ${drink.strength}'),
        onTap: () {
          _editConsumption(drink);
        },
      ));
      widgets.add(new Divider());
    }
    return widgets;
  }

  bool _onNotification(dynamic notif) {
    if (isDataChangeNotification(notif)) {
      setState(() {});
    }
    return false;
  }

  bool isDataChangeNotification(notif) =>
      notif.toString() == "DataChangeNotification()";

  @override
  Widget build(BuildContext context) {
    return new NotificationListener(
        onNotification: _onNotification,
        child: new Scaffold(
          drawer: new MyDrawer(this._scaffoldContext),
          appBar: new AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: new Text(widget.title),
            actions: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.cloud_download), onPressed: import),
              new IconButton(
                  icon: new Icon(Icons.cloud_upload), onPressed: exportData),
            ],
          ),
          body: new Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: new FutureBuilder<List<Drink>>(
            future: getFromDb(),
            builder:
                (BuildContext context, AsyncSnapshot<List<Drink>> snapshot) {
              this._scaffoldContext = context;
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return makeNewProgressIndicator();
                case ConnectionState.waiting:
                  return makeNewProgressIndicator();
                default:
                  if (!snapshot.hasError) {
                    this.data = snapshot.data;
                    return new Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildMainStats(snapshot.data),
                        new Divider(),
                        new Expanded(
                            child: new ListView(
                                children: getWidgetList(snapshot.data))),
                      ],
                    );
                  }
                  return new ListView(
                      children: <Widget>[new Text(snapshot.error.toString())]);
              }
            },
          )),
          floatingActionButton: new FloatingActionButton(
            onPressed: addConsumption,
            tooltip: 'Register new consumption',
            child: new Icon(Icons.add),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }

  Widget makeNewProgressIndicator() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Container(
          child: new CircularProgressIndicator(),
          margin: EdgeInsets.symmetric(vertical: 20.0),
        ),
        new Text("Loading data...")
      ],
    );
  }

  void _deleteConsumption(item) {
    setState(() {
      DrinkDatabase.get().deleteDrink(item);
    });
  }

  void _editConsumption(item) {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new UpsertConsumption(drink: item)),
    );
  }
}
