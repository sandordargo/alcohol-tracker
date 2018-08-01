import 'package:flutter/material.dart';
import 'dart:async';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/MyDrawer.dart';

// Define a Custom Form Widget
class Stats extends StatefulWidget {
  final String name;
  Stats({this.name});
  @override
  _StatsState createState() => new _StatsState(name: name);
}

class _StatsState extends State<Stats>{
  final emailController = new TextEditingController();
  final String name;
  BuildContext _scaffoldContext;
  _StatsState({this.name});


  Future<List<Drink>> getFromDb() async {
    var db = DrinkDatabase.get();
    List<Drink> drinks = await db.getAllDrinks();
    return drinks;
  }


  List<Widget> getWidgetList(List<Drink> drinks)  {

    var sum = 0.0;

    List<Widget> widgets = new List<Widget>();
    for (var drink in drinks) {
      sum += drink.unit;}

      widgets.add(new ListTile(
        title: new Text('units drunk ${sum}',
            style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0)),
        subtitle: new Text('85 W Portal Ave'),
        leading: new Icon(
          Icons.theaters,
          color: Colors.blue[500],
        ),
      ));

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      drawer: new MyDrawer(_scaffoldContext),
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text("lala"),
        actions: <Widget>[new IconButton(
            icon: new Icon(Icons.send),
            onPressed: null)],
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
          child: new FutureBuilder<List<Drink>>(
            future: getFromDb(),
            builder: (BuildContext context, AsyncSnapshot<List<Drink>> snapshot) {
              _scaffoldContext = context;
              switch (snapshot.connectionState) {
                case ConnectionState.none: return new ListView(
                  children: new List<Widget>(),
                );
                case ConnectionState.waiting: return new Text('Awaiting result...');
                default:
                  print('ss $snapshot');
                  print(snapshot.error);
                  print(snapshot.data);
                  if (!snapshot.hasError) {
                    return new ListView(children: getWidgetList(snapshot.data));
                  }
                  return new ListView(children: <Widget>[]);
              }
            },
          )
      ),
    );

  }
}
