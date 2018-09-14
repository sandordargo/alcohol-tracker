import 'package:flutter/material.dart';
import 'package:myapp/Drink.dart';
import 'package:date_format/date_format.dart';

class MainStats extends StatefulWidget {
  final List<Drink> drinks;
  final double weeklyLimit;
  final int weeklySoberDaysLimit;
  final int lastXDays;

  MainStats(
      this.drinks, this.weeklyLimit, this.weeklySoberDaysLimit, this.lastXDays);

  @override
  _MainStatsState createState() => new _MainStatsState(
      this.drinks, this.weeklyLimit, this.weeklySoberDaysLimit, this.lastXDays);
}

class _MainStatsState extends State<MainStats> {
  List<Drink> drinks;
  double weeklyLimit;
  int weeklySoberDaysLimit;
  int lastXDays = 7;

  _MainStatsState(
      this.drinks, this.weeklyLimit, this.weeklySoberDaysLimit, this.lastXDays);

  @override
  Widget build(BuildContext context) {
    return buildMainStats(
        this.drinks, this.weeklyLimit, this.weeklySoberDaysLimit);
  }

  refresh(int lastXDays) {
    setState(() {
      this.lastXDays = lastXDays;
    });
  }

  Widget buildMainStats(
      List<Drink> drinks, double weeklyLimit, int weeklySoberDaysLimit) {
    var unitsConsumedInLastXDays = 0.0;
    var daysDrink = new Set();
    for (var drink in drinks) {
      if (new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate)
          .isAfter(DateTime.now().subtract(new Duration(days: lastXDays)))) {
        unitsConsumedInLastXDays += drink.unit;
        var consDate =
            new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate);
        daysDrink
            .add(new DateTime(consDate.year, consDate.month, consDate.day));
      }
    }
    var maxDrinksADay = getMaxDrinksPerDay(drinks);
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        new Text(
          'During the last $lastXDays days you have had',
          style: new TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        new RichText(
          text: new TextSpan(
            style: new TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              new TextSpan(
                  text: '${unitsConsumedInLastXDays.toStringAsPrecision(2)}',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getColorForAlcoholConsumed(
                          unitsConsumedInLastXDays, weeklyLimit))),
              new TextSpan(text: ' units of alcohol consumed'),
            ],
          ),
        ),
        new RichText(
          text: new TextSpan(
            style: new TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              new TextSpan(
                  text: '${this.lastXDays - daysDrink.length}',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getColorForAlcoholFreeDays(
                          this.lastXDays - daysDrink.length,
                          weeklySoberDaysLimit))),
              new TextSpan(text: ' days without alcohol'),
            ],
          ),
        ),
        new Text(
            getAverageWrappingPhase(unitsConsumedInLastXDays, daysDrink.length),
            style: new TextStyle(fontSize: 20.0, color: Colors.black)),
        new Text(
            "Most alochol consumed during one day: "
            "${maxDrinksADay.value.toStringAsPrecision(2)} "
            "(${formatDate(maxDrinksADay.key, [yyyy, '-', mm, '-', dd])})",
            style: new TextStyle(fontSize: 20.0, color: Colors.black))
      ],
    );
  }

  String getAverageWrappingPhase(double consumedUnits, int numberOfDaysDrink) {
    double averageConsumption = consumedUnits / this.lastXDays;
    String basePhrase =
        "That's average of ${averageConsumption.toStringAsPrecision(2)} "
        "per day";
    if (numberOfDaysDrink > 0) {
      double averageConsumptionOnDrinkDays = consumedUnits / numberOfDaysDrink;
      basePhrase +=
          " and  ${averageConsumptionOnDrinkDays.toStringAsPrecision(2)} "
          "on the days you drank";
    }
    return basePhrase;
  }

  MapEntry<DateTime, double> getMaxDrinksPerDay(List<Drink> drinks) {
    Map<DateTime, double> drinksByDate = new Map();
    drinks.forEach((drink) {
      if (new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate)
          .isAfter(DateTime.now().subtract(new Duration(days: lastXDays)))) {
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
    MapEntry<DateTime, double> biggest = new MapEntry(DateTime.now(), 0.0);
    drinksByDate.forEach((date, unit) {
      if (unit > biggest.value) {
        biggest = new MapEntry(date, unit);
      }
    });
    return biggest;
  }

  Color getColorForAlcoholConsumed(
      double unitsConsumedInLastXDays, double weeklyLimit) {
    double limit = weeklyLimit * this.lastXDays / 7;
    return unitsConsumedInLastXDays > limit ? Colors.red : Colors.green;
  }

  Color getColorForAlcoholFreeDays(
      int alcoholFreeDays, int weeklySoberDaysLimit) {
    double limit = weeklySoberDaysLimit * this.lastXDays / 7;
    return alcoholFreeDays < limit ? Colors.red : Colors.green;
  }
}
