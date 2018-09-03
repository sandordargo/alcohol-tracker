import 'package:flutter/material.dart';
import 'dart:async';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'package:myapp/MyDrawer.dart';
import 'package:myapp/MainStats.dart';
import 'package:myapp/prefs.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class AlcoholPerDay {
  final DateTime day;
  final double unitsOfAlcohol;

  AlcoholPerDay(this.day, this.unitsOfAlcohol);
}

class Stats extends StatefulWidget {
  Stats();

  @override
  _StatsState createState() => new _StatsState();
}

class _StatsState extends State<Stats> {
  BuildContext _scaffoldContext;
  double _weeklyLimit;
  int _weeklySoberDaysLimit;
  Prefs prefs;
  List<Drink> drinks;
  int lookBackXDays = 7;

  @override
  void initState() {
    super.initState();
    _setWeeklyLimit();
    _setWeeklySoberDaysLimit();
  }

  void _setWeeklyLimit() async {
    this._weeklyLimit = await Prefs.getDoubleF("weeklyLimit");
    this._weeklyLimit = this._weeklyLimit == 0.0 ? 10.0 : this._weeklyLimit;
  }

  void _setWeeklySoberDaysLimit() async {
    this._weeklySoberDaysLimit = await Prefs.getIntF("soberDaysLimit");
    this._weeklySoberDaysLimit =
        this._weeklyLimit == 0 ? 2 : this._weeklySoberDaysLimit;
  }

  Future<List<Drink>> _fetchDrinks() async {
    return await DrinkDatabase.get().getAllDrinks();
  }

  List<AlcoholPerDay> _collectWeeklyConsumption() {
    List<AlcoholPerDay> weeklyConsumptions = new List();

    for (var day = 1; day <= this.lookBackXDays; day++) {
      AlcoholPerDay weeklyConsumption = _calculateWeeklyConsumption(day);
      weeklyConsumptions.add(weeklyConsumption);
    }

    return weeklyConsumptions;
  }

  AlcoholPerDay _calculateWeeklyConsumption(int day) {
    var unitsConsumedInLast7Days = 0.0;
    this.drinks.forEach((drink) {
      if (_isWithinAWeek(drink, day)) {
        unitsConsumedInLast7Days += drink.unit;
      }
    });

    var lookBackDay =
        new DateTime.now().subtract(new Duration(days: lookBackXDays - day));

    var lookBackDayMidnight =
        new DateTime(lookBackDay.year, lookBackDay.month, lookBackDay.day);

    var weeklyConsumption =
        new AlcoholPerDay(lookBackDayMidnight, unitsConsumedInLast7Days);
    return weeklyConsumption;
  }

  bool _isWithinAWeek(Drink drink, int day) {
    return new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate)
            .isAfter(DateTime.now().subtract(
                new Duration(days: lookBackXDays - day) +
                    new Duration(days: 7))) &&
        new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate).isBefore(
            DateTime.now().subtract(new Duration(days: lookBackXDays - day)));
  }

  List<AlcoholPerDay> _collectDailyConsumptions() {
    Map<DateTime, double> drinksByDate = new Map();
    this.drinks.forEach((drink) {
      if (new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate)
          .isAfter(DateTime
              .now()
              .subtract(new Duration(days: this.lookBackXDays)))) {
        DateTime consumptionDate =
            DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate);
        DateTime consumptionDay = new DateTime(
            consumptionDate.year, consumptionDate.month, consumptionDate.day);
        if (!drinksByDate.containsKey(consumptionDay)) {
          drinksByDate[consumptionDay] = 0.0;
        }
        drinksByDate[consumptionDay] += drink.unit;
      }
    });

    List<AlcoholPerDay> dailyConsumptions = new List();
    drinksByDate.forEach((date, units) {
      dailyConsumptions.add(new AlcoholPerDay(date, units));
    });
    return dailyConsumptions;
  }

  Widget _buildChartWidget() {
    var chartWidget = new Padding(
      padding: new EdgeInsets.all(32.0),
      child: new SizedBox(
        height: 200.0,
        child: _buildChart(),
      ),
    );
    return chartWidget;
  }

  charts.TimeSeriesChart _buildChart() {
    var chart = new charts.TimeSeriesChart(
      _buildChartSeries(),
      animate: false,
      behaviors: [
        new charts.SeriesLegend(position: charts.BehaviorPosition.bottom),
      ],
      primaryMeasureAxis: new charts.NumericAxisSpec(
          tickProviderSpec:
              new charts.BasicNumericTickProviderSpec(desiredTickCount: 5)),
      customSeriesRenderers: [
        new charts.PointRendererConfig(
          customRendererId: 'dotRendering',
        )
      ],
    );
    return chart;
  }

  List<charts.Series<AlcoholPerDay, DateTime>> _buildChartSeries() {
    final List<charts.Series<AlcoholPerDay, DateTime>> series = [
      new charts.Series<AlcoholPerDay, DateTime>(
        id: 'Last 7 day consumption',
        domainFn: (AlcoholPerDay alcoholPerDay, _) => alcoholPerDay.day,
        measureFn: (AlcoholPerDay alcoholPerDay, _) =>
            alcoholPerDay.unitsOfAlcohol,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        data: _collectWeeklyConsumption(),
      ),
      new charts.Series<AlcoholPerDay, DateTime>(
        id: 'Daily consumption',
        domainFn: (AlcoholPerDay alcoholPerDay, _) => alcoholPerDay.day,
        measureFn: (AlcoholPerDay alcoholPerDay, _) =>
            alcoholPerDay.unitsOfAlcohol,
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        data: _collectDailyConsumptions(),
      )..setAttribute(charts.rendererIdKey, 'dotRendering'),
    ];
    return series;
  }

  DropdownButton _buildLengthSelector(BuildContext context) {
    var menuItems = <int>[7, 30, 90].map((int length) {
      return new DropdownMenuItem(
          value: length, child: new Text("Last $length days"));
    }).toList();
    return new DropdownButton(
        items: menuItems,
        value: this.lookBackXDays,
        onChanged: (value) {
          setState(() {
            this.lookBackXDays = value;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: new MyDrawer(_scaffoldContext),
      appBar: new AppBar(
        title: new Text("Statistics"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.send), onPressed: null)
        ],
      ),
      body: new Center(
          child: new FutureBuilder<List<Drink>>(
        future: _fetchDrinks(),
        builder: (BuildContext context, AsyncSnapshot<List<Drink>> snapshot) {
          _scaffoldContext = context;
          _setWeeklyLimit();
          _setWeeklySoberDaysLimit();
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return new ListView(
                children: new List<Widget>(),
              );
            case ConnectionState.waiting:
              return new Text('Awaiting result...');
            default:
              drinks = snapshot.data;
              return new ListView(
                children: <Widget>[
                  _buildLengthSelector(context),
                  MainStats(drinks, _weeklyLimit, _weeklySoberDaysLimit,
                      this.lookBackXDays),
                  _buildChartWidget(),
                ],
              );
          }
        },
      )),
    );
  }
}
