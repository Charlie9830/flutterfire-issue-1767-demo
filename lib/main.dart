// A demonstration of FlutterFire issue #1767.
// https://github.com/FirebaseExtended/flutterfire/issues/1767

// Issue Brief:
// Firebase Auth triggers a User log out event when they are Reauthenticating their Email and Password credential using an email that points to a non existant User within
// Firebase Authentication.

// Unfortunately I do no have the means to test if this issue occurs on iOS. I can however confirm that it occurs on Android. 

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const correctEmail = 'test@test.com';
const correctPassword = 'testpassword';
const incorrectEmail = 'incorrect@test.com';
const incorrectPassword = 'incorrectPassword';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterFire #1767 Demonstration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'FlutterFire #1767 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    FirebaseAuth.instance.onAuthStateChanged.listen(_handleAuthStateChanged);
    super.initState();
  }

  // Listen to Firebase Auth State Changes. We are expecting this to be called in error after reauthenticating the user with an incorrect email address.
  void _handleAuthStateChanged(FirebaseUser user) {
    if (user == null) {
      // Logged Out.
      setState(() {
        _isLoggedIn = false;
      });
    } else {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  // Log the user in with the correct Email and Password.
  void _handleLogInUserButtonPress() async {
    FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correctEmail, password: correctPassword);
  }

  // Call reauthenticateWithCredential using an email that points to a non existant user.
  // This will throw a PlatformException "ERROR_USER_NOT_FOUND" as expected, however it will also trigger a Log out event, calling the onAuthStateChanged handler.
  // For ease of use of this demo, we catch but do nothing with the Platform Exception.
  void _reauthenticateWithIncorrectDetails() async {
    final user = await FirebaseAuth.instance.currentUser();

    try {
      final result = await user.reauthenticateWithCredential(
          EmailAuthProvider.getCredential(
              email: incorrectEmail, password: incorrectPassword));
    } on PlatformException catch (error) {
      if (error.code == "ERROR_USER_NOT_FOUND") {
        print('User not Found Error Triggered');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isLoggedIn ? 'Logged IN' : 'Logged OUT',
                style: Theme.of(context).textTheme.headline6),
            Text('Step 1: Log the user in'),
            RaisedButton(
              child: Text('Log in User'),
              onPressed: _handleLogInUserButtonPress,
            ),
            Text('Step 2: Reauthenticate the user with an incorrect Email'),
            RaisedButton(
              child: Text('Reauthenticate with INCORRECT Details'),
              onPressed:
                  _isLoggedIn ? _reauthenticateWithIncorrectDetails : null,
            ),
            Text('Step 3: Notice that the user has now been logged out.')
          ],
        ),
      ),
    );
  }
}
