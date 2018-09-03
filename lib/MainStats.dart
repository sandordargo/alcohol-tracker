import 'package:flutter/material.dart';
import 'package:myapp/Drink.dart';


Widget buildMainStats(List<Drink> drinks, double weeklyLimit, int weeklySoberDaysLimit) {
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
                        unitsConsumedInLast7Days, weeklyLimit))),
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
                    color: getColorForAlcoholFreeDays(7 - daysDrink.length, weeklySoberDaysLimit))),
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

Color getColorForAlcoholConsumed(double unitsConsumedInLast7Days, double weeklyLimit) {
  return unitsConsumedInLast7Days > weeklyLimit ? Colors.red : Colors.green;
}

Color getColorForAlcoholFreeDays(int alcoholFreeDays, int weeklySoberDaysLimit) {
  return alcoholFreeDays < weeklySoberDaysLimit ? Colors.red : Colors.green;
}
