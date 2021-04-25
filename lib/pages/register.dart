import 'package:ask_help_app/main.dart';
import 'package:ask_help_app/pages/home.dart';
import 'package:ask_help_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';

class Register extends StatefulWidget {
  Register({Key key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _nameTextEditingController =
      TextEditingController();
  final TextEditingController _emailTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Sign Up',
                  style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextField(
                      controller: _nameTextEditingController,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email Address",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextField(
                      controller: _emailTextEditingController,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextField(
                      controller: _passwordTextEditingController,
                      obscureText: true,
                    ),
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                ElevatedButton(
                  onPressed: () async {
                    String name = _nameTextEditingController.text.trim();
                    String email = _emailTextEditingController.text.trim();
                    String password =
                        _passwordTextEditingController.text.trim();

                    if (email.isEmpty || password.isEmpty || name.isEmpty) {
                      Fluttertoast.showToast(msg: 'All fields are required');
                      return;
                    }

                    User user = await AuthService().register(email, password);
                    await user.updateProfile(displayName: name);
                    await users.doc(user.uid).set({
                      "name": name,
                      "email": email,
                    });

                    if (user == null) {
                      Fluttertoast.showToast(msg: 'Invalid login attempt');
                      return;
                    }

                    if (user != null) {
                      mUser = user;
                      print('user display name: ${user.displayName}');
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Home(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    primary: Colors.white,
                  ),
                  child: Text(
                    'Register',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 44),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Login(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Login',
                      style: GoogleFonts.lato(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
