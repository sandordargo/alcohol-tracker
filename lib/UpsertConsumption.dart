import 'package:flutter/material.dart';
import 'package:myapp/DrinkDatabase.dart';
import 'package:myapp/Drink.dart';
import 'dart:async';
import 'package:date_format/date_format.dart';

class UpsertConsumption extends StatefulWidget {
  final Drink drink;

  UpsertConsumption({this.drink});

  @override
  _UpsertConsumptionState createState() =>
      new _UpsertConsumptionState(drink: this.drink);
}

// add margins to suffixes
// drop down drinks
// smart text for date
// save last volume and offer that from drop down
// ml or cl
// drop down for drinks

class _UpsertConsumptionState extends State<UpsertConsumption> {
  Drink drink;
  TextEditingController titleController;
  TextEditingController volumeController;
  TextEditingController strengthController;
  TextEditingController remarkController;
  DateTime selectedDay;
  Text selectedDayText;
  Text consumedUnitsText;
  double consumedUnits;
  final _formKey = GlobalKey<FormState>();

  _UpsertConsumptionState({this.drink}) {
    titleController =
        new TextEditingController(text: drink == null ? null : drink.name);
    volumeController = new TextEditingController(
        text: drink == null ? null : drink.volume.toString());
    strengthController = new TextEditingController(
        text: drink == null ? null : drink.strength.toString());
    remarkController =
        new TextEditingController(text: drink == null ? null : drink.remark);
    selectedDay = drink == null
        ? _getTodayAtMindnight()
        : new DateTime.fromMillisecondsSinceEpoch(drink.consumptionDate);
    selectedDayText = new Text("You had this drink on (${formatDate(selectedDay,
        [yyyy, '-', mm, '-', dd])})");
    consumedUnits =
        drink == null ? 0.0 : drink.volume * (drink.strength / 100) * (8 / 100);
    consumedUnitsText =
        new Text("That's a drink of ${consumedUnits.toStringAsPrecision(
            2)} units of alcohol.");
  }

  DateTime _getTodayAtMindnight() {
    DateTime now = new DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    volumeController.addListener(_updateConsumedUnits);
    strengthController.addListener(_updateConsumedUnits);
  }

  @override
  void dispose() {
    volumeController.removeListener(_updateConsumedUnits);
    strengthController.removeListener(_updateConsumedUnits);
  }


  void _updateConsumedUnits() {
    consumedUnits = int.parse(volumeController.text) *
        (double.parse(strengthController.text) / 100) *
        (8 / 100);
    consumedUnitsText = new Text(
        "That's a drink of ${consumedUnits.toStringAsPrecision(
            2)} units of alcohol.");
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDay,
        firstDate: new DateTime.now().subtract(new Duration(days: 60)),
        lastDate: new DateTime.now());

    if (picked != null && picked != selectedDay) {
      print('Date selected: ${selectedDay.toString()}');
      setState(() {
        selectedDay = picked;
        selectedDayText =
            new Text("You had this drink on ${formatDate(selectedDay,
            [yyyy, '-', mm, '-', dd])}.");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(drink == null
              ? "Add a drink you consumed"
              : "Edit a past consumption"),
        ),
        body: new Form(
          key: _formKey,
          child: new Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: new Column(children: [
              new Container(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: new TextFormField(
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                  },
                  controller: titleController,
                  keyboardType: TextInputType.text,
                  decoration: new InputDecoration(
                      border: InputBorder.none,
                      labelText: 'What did you drink?'),
                ),
              ),
              new Container(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: new TextFormField(
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please a volume text';
                    }
                  },
                  controller: volumeController,
                  keyboardType: TextInputType.number,
                  decoration: new InputDecoration(
                      border: InputBorder.none,
                      suffixText: "ml",
                      labelText: 'How much did you drink in milliliters?'),
                ),
              ),
              new Container(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: new TextFormField(
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter the strength';
                    }
                  },
                  controller: strengthController,
                  keyboardType: TextInputType.number,
                  decoration: new InputDecoration(
                      border: InputBorder.none,
                      labelText:
                          'How strong was it? (12% for an average red wine)',
                      suffixText: "%"),
                ),
              ),
              new Container(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        selectedDayText,
                        new Container(
                            margin: const EdgeInsets.only(right: 15.0),
                            child: new RaisedButton(
                                child: new Text('Change Date'),
                                onPressed: () {
                                  _selectDate(context);
                                }))
                      ])),
              new Container(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: new TextField(
                  controller: remarkController,
                  onChanged: (text) {
                    print("First text field: $text");
                  },
                  keyboardType: TextInputType.text,
                  decoration: new InputDecoration(
                      border: InputBorder.none, hintText: 'Any remark to add?'),
                ),
              ),
              new Container(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: consumedUnitsText),
              new Container(
                  child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  new Container(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: new RaisedButton(
                        onPressed: () {
                          if (!_formKey.currentState.validate()) {
                            return null;
                          }
                          Navigator.pop(context);
                          var db = DrinkDatabase.get();
                          Drink consumption = new Drink(
                              id: drink != null ? drink.id : null,
                              name: titleController.text,
                              volume: int.parse(volumeController.text),
                              strength: double.parse(strengthController.text),
                              unit: consumedUnits,
                              consumptionDate:
                                  selectedDay.millisecondsSinceEpoch,
                              remark: remarkController.text);
                          db.upsertDrink(consumption);

                          return showDialog(
                            context: context,
                            builder: (context) {
                              return new AlertDialog(
                                // Retrieve the text the user has typed in using our
                                // TextEditingController
                                content:
                                    new Text("You consumed, ${titleController
                                        .text}"),
                              );
                            },
                          );
                        },
                        child: new Text('Save',
                            style: new TextStyle(color: Colors.white)),
                        color: Colors.green,
                      )),
                  new Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: new RaisedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: new Text('Cancel',
                            style: new TextStyle(color: Colors.white)),
                        color: Colors.red,
                      ))
                ],
              )),
            ]),
          ),
        ));
  }
}
