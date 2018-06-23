import 'package:flutter/material.dart';
import 'package:myapp/AddConsumption.dart';
import 'package:myapp/EditConsumption.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/Stats.dart';
import 'package:myapp/Import.dart';
import 'dart:async';
import 'package:myapp/ExportData.dart';
import 'package:date_format/date_format.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Alcohol Consumption Tracker',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Alcohol Consumption Tracker Home'),
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
      new MaterialPageRoute(builder: (context) => new RegisterConsumption()),
    );
  }


  void import() {
   Navigator.push(
     context,
     new MaterialPageRoute(builder: (context) => new Import(_scaffoldContext)),
   );
  }

  void exportData() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new ExportData(data)),
    );
  }

  void stats() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new Stats(name: "pia")),
    );
  }

  Future<List<Drink>> getFromDb() async {
    return await DrinkDatabase.get().getAllDrinks();
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
              child: new IconButton(icon: new Icon(Icons.delete), onPressed: (){_deleteConsumption(drink);},),
//              margin: const EdgeInsets.symmetric(horizontal: 0.5)
          ),
        title: new Text(
            '${drink.name[0].toUpperCase() + drink.name.substring(1)}, ${drink
                .unit.toStringAsPrecision(2)} units of alcohol',
            style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0),),
        subtitle: new Text('Volume: ${drink.volume}, strength: ${drink.strength}'),
        onTap: (){_editConsumption(drink);},

      ));
      widgets.add(new Divider());
    }
    return widgets;
  }

  Widget getMainStats(List<Drink> drinks) {
    var soberDaysInLast7Days = 0;
    var unitsConsumedInLast7Days = 0.0;
    var daysDrink = new Set();
    for (var drink in drinks) {
      if (new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate)
          .isAfter(DateTime.now().subtract(new Duration(days: 7)))) {
        unitsConsumedInLast7Days += drink.unit;
        var consDate =
            new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate);
        daysDrink
            .add(new DateTime(consDate.year, consDate.month, consDate.day));
      }
    }
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        new Text(
          'During the last 7 days you have had',
          style: new TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        new RichText(
          text: new TextSpan(
            // Note: Styles for TextSpans must be explicitly defined.
            // Child text spans will inherit styles from parent
            style: new TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              new TextSpan(
                  text: '${unitsConsumedInLast7Days.toStringAsPrecision(2)}',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getColorForAlcoholConsumed(
                          unitsConsumedInLast7Days))),
              new TextSpan(text: ' units of alcohol consumed'),
            ],
          ),
        ),
        new RichText(
          text: new TextSpan(
            // Note: Styles for TextSpans must be explicitly defined.
            // Child text spans will inherit styles from parent
            style: new TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              new TextSpan(
                  text: '${7 - daysDrink.length}',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getColorForAlcoholFreeDays(7 - daysDrink.length))),
              new TextSpan(text: ' days without alcohol'),
            ],
          ),
        ),
        new Text(
            "That's average of ${(unitsConsumedInLast7Days / 7)
                .toStringAsPrecision(2)} per day and "
            "${(unitsConsumedInLast7Days / daysDrink.length)
                .toStringAsPrecision(2)} on the days you drank",
            style: new TextStyle(fontSize: 20.0, color: Colors.black))
      ],
    );
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
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.cloud_download), onPressed: import),
          new FlatButton(onPressed: exportData, child: new Text("Export data")),
          new FlatButton(onPressed: stats, child: new Text("Stats"))
        ],
      ),
      body: new Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: new FutureBuilder<List<Drink>>(
        future: getFromDb(),
        builder: (BuildContext context, AsyncSnapshot<List<Drink>> snapshot) {
          this._scaffoldContext = context;
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return new ListView(
                children: new List<Widget>(),
              );
            case ConnectionState.waiting:
              return new Text('Awaiting result...');
            default:
              print('ss $snapshot');
              print(snapshot.error);
              print(snapshot.data);
              if (!snapshot.hasError) {
//                  return new ListView(children: getWidgetList(snapshot.data));
              this.data = snapshot.data;
                return new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getMainStats(snapshot.data),
                    new Divider(),
                    new Expanded(
                        child: new ListView(
                            children: getWidgetList(snapshot.data))
                    ),
                  ],
                );
              }
              return new ListView(children: <Widget>[]);
          }
        },
      )),
      floatingActionButton: new FloatingActionButton(
        onPressed: addConsumption,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Color getColorForAlcoholConsumed(double unitsConsumedInLast7Days) {
    return unitsConsumedInLast7Days > 10.0 ? Colors.red : Colors.green;
  }

  Color getColorForAlcoholFreeDays(int alcoholFreeDays) {
    return alcoholFreeDays < 2 ? Colors.red : Colors.green;
  }

  void _deleteConsumption(item) {
    setState(() {
      DrinkDatabase.get().deleteDrink(item);

    });
    showDialog(context: context, builder: (context) {
      return new AlertDialog(
        title: new Text("You want to delete $item"),
      );
    }
    );
  }

  void _editConsumption(item) {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new EditConsumption(item)),
    );
  }
}
