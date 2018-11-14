import 'package:flutter/material.dart';
import 'package:myapp/ListDrinks.dart';

void main() => runApp(new MyApp());

class DataChangeNotification extends Notification {}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'BoozeTracker',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ListDrinks(title: 'Last 30 Days'),
    );
  }
}
