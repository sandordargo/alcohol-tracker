import 'package:flutter/material.dart';
import 'package:myapp/prefs.dart';

class Settings extends StatefulWidget {
  Settings();

  @override
  _SettingsState createState() => new _SettingsState();
}

class _SettingsState extends State<Settings> with WidgetsBindingObserver {
  TextEditingController _weeklyLimitController = new TextEditingController();
  TextEditingController _weeklySoberDaysController =
      new TextEditingController();
  FocusNode _weeklyLimitFocus = new FocusNode();
  FocusNode _weeklySoberDaysFocus = new FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weeklyLimitFocus.addListener(_weeklyLimitFocusChange);
    _weeklySoberDaysFocus.addListener(_weeklySoberDaysFocusChange);
    setControllers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weeklyLimitFocus.removeListener(_weeklyLimitFocusChange);
    _weeklySoberDaysFocus.removeListener(_weeklySoberDaysFocusChange);
    super.dispose();
  }

  void _weeklyLimitFocusChange() {
    if (_weeklyLimitFocus.hasFocus) {
      _weeklyLimitController.selection = new TextSelection(
          baseOffset: 0, extentOffset: _weeklyLimitController.text.length);
    }
  }

  void _weeklySoberDaysFocusChange() {
    if (_weeklySoberDaysFocus.hasFocus) {
      _weeklySoberDaysController.selection = new TextSelection(
          baseOffset: 0, extentOffset: _weeklySoberDaysController.text.length);
    }
  }

  void setControllers() async {
    print('reload controllers');
    double weeklyLimit = await Prefs.getDoubleF("weeklyLimit");
    int soberDaysLimit = await Prefs.getIntF("soberDaysLimit");
    _weeklyLimitController.text =
        weeklyLimit > 0 ? weeklyLimit.toString() : "10.0";
    _weeklySoberDaysController.text =
        soberDaysLimit > 0 ? soberDaysLimit.toString() : "2";
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      setControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Settings"),
        ),
        body: new Column(
          children: <Widget>[
            new TextField(
              controller: _weeklyLimitController,
              focusNode: _weeklyLimitFocus,
              decoration: new InputDecoration(labelText: "Weekly Limit"),
            ),
            new TextField(
              controller: _weeklySoberDaysController,
              focusNode: _weeklySoberDaysFocus,
              decoration: new InputDecoration(
                  labelText: "Days Without Alcohol per 7 Days"),
            ),
            new Container(
                margin: EdgeInsets.only(top: 50.0),
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: new RaisedButton(
                            child: const Text('Done'),
                            onPressed: () {
                              Prefs.setInt("soberDaysLimit",
                                  int.parse(_weeklySoberDaysController.text));
                              Prefs.setDouble("weeklyLimit",
                                  double.parse(_weeklyLimitController.text));
                              Navigator.pop(context);
                            },
                          )),
                      new Container(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: new RaisedButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )),
                    ]))
          ],
        ));
  }
}
