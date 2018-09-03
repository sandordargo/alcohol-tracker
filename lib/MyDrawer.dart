import 'package:flutter/material.dart';
import 'package:myapp/Stats.dart';
import 'package:myapp/ListAllDrinks.dart';
import 'package:myapp/main.dart';
import 'package:myapp/HyperLinkTextSpan.dart';
import 'package:myapp/ImportV2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/SignInContainer.dart';
import 'package:myapp/Settings.dart';

class MyDrawer extends StatefulWidget {
  final BuildContext _scaffoldContext;

  MyDrawer(this._scaffoldContext);

  @override
  _MyDrawerState createState() => new _MyDrawerState(_scaffoldContext);
}

class _MyDrawerState extends State<MyDrawer> {
  final BuildContext _scaffoldContext;
  GoogleSignInAccount _currentUser;
  SignInContainer _signInContainer = new SignInContainer();

  _MyDrawerState(this._scaffoldContext);

  @override
  void initState() {
    super.initState();
    _currentUser = _signInContainer.getCurrentUser();
    _signInContainer.listen((account) {
      _currentUser = account;
      if (this.mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext ctxt) {
    return new Drawer(
        child: new ListView(
      children: <Widget>[
        new DrawerHeader(
//              child: new Text("Alcohol Consumption Tracker", style: new TextStyle(color: Colors.white)),
          child: new Column(
            children: <Widget>[getTitle()],
          ),
//              child:  new GoogleUserCircleAvatar( identity: _currentUser,),
          decoration: new BoxDecoration(color: Colors.blue),
        ),
        new ListTile(
          title: new Text("Last 30 days"),
          onTap: () {
            Navigator.pop(ctxt);
            Navigator.push(
                ctxt,
                new MaterialPageRoute(
                    builder: (ctxt) => new MyHomePage(title: "Last 30 days")));
          },
        ),
        new ListTile(
          title: new Text("All The Drinks"),
          onTap: () {
            Navigator.pop(ctxt);
            Navigator.push(ctxt,
                new MaterialPageRoute(builder: (ctxt) => new AllDrinksList()));
          },
        ),
        new ListTile(
          title: new Text("Statistics"),
          onTap: () {
            Navigator.pop(ctxt);
            Navigator.push(
                ctxt, new MaterialPageRoute(builder: (ctxt) => new Stats()));
          },
        ),
        new ListTile(
          title: new Text("Import"),
          onTap: () {
            Navigator.pop(ctxt);
            Navigator.push(
                ctxt,
                new MaterialPageRoute(
                    builder: (ctxt) => new ImportV2(_scaffoldContext)));
          },
        ),
        new ListTile(
          title: Text("Settings"),
          onTap: () {
            Navigator.pop(ctxt);
            Navigator.push(
                ctxt,
                new MaterialPageRoute(
                    builder: (ctxt) => new Settings()));
          },
        ),
        new ListTile(
          title: new Text("About"),
          onTap: () {
            {
              Navigator.pop(ctxt);
              AlertDialog dialog = new AlertDialog(
                  content: new RichText(
                      textAlign: TextAlign.justify,
                      text: new TextSpan(
                          text:
                              "This app is not for anti-alcoholics nor for alcoholics trying to quit booze.\n\n"
                              "They need an other type of help.\n\n"
                              "AlcoholTracker is for you if you are interested in tracking how much alcohol "
                              "you consume. It helps you seting a limit or just "
                              "following the guidelines suggested by different organizations. "
                              "For any suggestions, feel free to contact me at ",
                          style: new TextStyle(
                              fontSize: 20.0, color: Colors.black),
                          children: [
                            new HyperLinkTextSpan(
                                text: "dev.sandor@gmail.com",
                                url:
                                    "mailto:dev.sandor@gmai.com?subject=About AlcoholTracker",
                                style: new TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline)),
                            new TextSpan(text: ".")
                          ])));
              showDialog(context: ctxt, builder: (context) => dialog);
            }
          },
        )
      ],
    ));
  }

  Widget getTitle() {
    if (_currentUser == null) {
      return new ListTile(
        leading: getLead(),
        title: new Text("Sign in"),
        onTap: _signInContainer.handleSignIn,
      );
    }
    return new ListTile(
      leading: getLead(),
      title: new Text(_currentUser.displayName),
      subtitle: new Text(_currentUser.email),
      onTap: _signInContainer.handleSignOut,
    );
  }

  Widget getLead() {
    if (_currentUser == null) {
      return new CircleAvatar(child: new Text("?"));
    }
    return new GoogleUserCircleAvatar(
      identity: _currentUser,
    );
  }
}
