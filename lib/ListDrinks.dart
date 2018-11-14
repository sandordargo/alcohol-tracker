import 'package:flutter/material.dart';
import 'package:myapp/UpsertConsumption.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/DataImporter.dart';
import 'dart:async';
import 'package:myapp/DataUploader.dart';
import 'package:myapp/MainStats.dart';
import 'package:myapp/MyDrawer.dart';
import 'package:date_format/date_format.dart';
import 'package:myapp/prefs.dart';
import 'package:connectivity/connectivity.dart';

class ListDrinks extends StatefulWidget {
  ListDrinks({Key key, this.title, this.fetchAll=false}) : super(key: key);

  final String title;
  final bool fetchAll;

  @override
  _ListDrinksState createState() => new _ListDrinksState(fetchAll);
}

class _ListDrinksState extends State<ListDrinks> with WidgetsBindingObserver {
  BuildContext _scaffoldContext;
  List<Drink> data = new List();
  double _weeklyLimit;
  int _weeklySoberDaysLimit;
  Prefs prefs;
  final bool fetchAll;

  _ListDrinksState(this.fetchAll);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setWeeklyLimit();
    setWeeklySoberDaysLimit();
    _synchronizeAutomatically();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _synchronizeAutomatically();
    });
  }

  void _synchronizeAutomatically() async {
    List<Drink> drinks = await DrinkDatabase.get().getAllDrinks();
    var lastSynch = await Prefs.getIntF("last_sync");
    var lastSynchDate = new DateTime.fromMillisecondsSinceEpoch(lastSynch);
    if ((await Prefs.getBoolF("sync_needed") && lastSynchDate.add(new Duration(seconds: 10)).isBefore(new DateTime.now()))
        || data.isEmpty && drinks.isEmpty) {
      var connectivityResult = await (new Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        _synchronize();
      }
    }
  }

  void _synchronize() async {
    List<Drink> drinks = await DrinkDatabase.get().getAllDrinks();
    if (data.isEmpty && drinks.isEmpty) {
      var importer = new DataImporter(_scaffoldContext);
      importer.import();
    } else {
      var uploader = DataUploader(drinks, _scaffoldContext);
      uploader.upload();
    }
  }

  void setWeeklyLimit() async {
    this._weeklyLimit = await Prefs.getDoubleF("weeklyLimit");
    this._weeklyLimit = this._weeklyLimit == 0.0 ? 10.0 : this._weeklyLimit;
  }

  void setWeeklySoberDaysLimit() async {
    this._weeklySoberDaysLimit = await Prefs.getIntF("soberDaysLimit");
    this._weeklySoberDaysLimit =
    this._weeklyLimit == 0 ? 2 : this._weeklySoberDaysLimit;
  }

  void addConsumption() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new UpsertConsumption(_scaffoldContext)),
    );
  }

  Future<List<Drink>> getFromDb() async {
    if (this.fetchAll) {
      return await DrinkDatabase.get().getAllDrinks();
    }
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
      setState(() {
      });
    }
    _synchronizeAutomatically();
    return false;
  }

  bool isDataChangeNotification(notif) =>
      notif.toString() == "DataChangeNotification()";

  @override
  Widget build(BuildContext context) {
    return new NotificationListener(
        onNotification: _onNotification,
        child: new Scaffold(
          drawer: new MyDrawer(),
          appBar: new AppBar(

            title: new Text(widget.title),
            actions: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.sync), onPressed: _synchronize),
            ],
          ),
          body: new Center(
              child: new FutureBuilder<List<Drink>>(
                future: getFromDb(),
                builder:
                    (BuildContext context, AsyncSnapshot<List<Drink>> snapshot) {
                  setWeeklyLimit();
                  setWeeklySoberDaysLimit();
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

                            new MainStats(snapshot.data, this._weeklyLimit, this._weeklySoberDaysLimit, 7),
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
      Prefs.setBool("sync_needed", true);
      _synchronizeAutomatically();
    });
  }

  void _editConsumption(item) {
    Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) => new UpsertConsumption(_scaffoldContext, drink: item)),
    );
  }
}
