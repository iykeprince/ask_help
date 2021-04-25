import 'package:ask_help_app/data_handlers/app_data.dart';
import 'package:ask_help_app/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './pages/home.dart';

String mapKey = 'AIzaSyDKFRPM_2zrr1J14al_9_4Vi80jWV_S6G8';

final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
FirebaseFirestore _firestore = FirebaseFirestore.instance;
CollectionReference users = _firestore.collection('users');
CollectionReference locations = _firestore.collection('locations');
User mUser = null;
FirebaseAuth mAuth = FirebaseAuth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _authenticated = false;
  @override
  void initState() {
    super.initState();
    mAuth.authStateChanges().listen((User user) {
      bool value = false;
      if (user == null) {
        print('User is currently signed out!');
        value = false;
      } else {
        print('User is signed in!');
        value = true;
      }
      setState(() {
        _authenticated = value;
        mUser = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ask Help',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: !_authenticated ? Login() : Home(),
      ),
    );
  }
}
