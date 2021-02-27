import 'package:flutter/material.dart';

import '../api.dart';

class LoginPage extends StatefulWidget {
  final String title = 'Fotoalbum';
  final ValueChanged<LoginResponse> onLoggedIn;

  LoginPage({Key key, @required this.onLoggedIn}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

enum LoginInputState { Login, Register }

class LoginPageState extends State<LoginPage> {
  LoginInputState inputState = LoginInputState.Login;
  final formKey = GlobalKey<FormState>();
  final usernameKey = GlobalKey<FormFieldState>();
  final passKey = GlobalKey<FormFieldState>();

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: FlatButton(
                    child: Text(
                      'Log ind',
                      style: TextStyle(
                        color: inputState == LoginInputState.Login
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColorLight,
                      ),
                    ),
                    onPressed: () => setInputState(LoginInputState.Login),
                  ),
                ),
                Container(
                  child: FlatButton(
                    child: Text(
                      'Lav ny bruger',
                      style: TextStyle(
                        color: inputState == LoginInputState.Register
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColorLight,
                      ),
                    ),
                    onPressed: () => setInputState(LoginInputState.Register),
                  ),
                ),
              ],
            ),
            if (1 == 1)
              Container(
                padding: EdgeInsets.all(20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        key: usernameKey,
                        decoration: const InputDecoration(
                            labelText: 'Brugernavn',
                            floatingLabelBehavior: FloatingLabelBehavior.auto),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Brugernavn må ikke være tomt';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        key: passKey,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Kodeord',
                            floatingLabelBehavior: FloatingLabelBehavior.auto),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Kodeordet må ikke være tomt';
                          }
                          return null;
                        },
                      ),
                      if (inputState == LoginInputState.Register)
                        TextFormField(
                          obscureText: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                              labelText: 'Bekræft kodeord',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.auto),
                          validator: (value) {
                            if (passKey.currentState.value != value) {
                              return 'De to kodeord skal være ens';
                            }

                            return null;
                          },
                        ),
                      RaisedButton(
                        onPressed: () async {
                          String username = 'sven';
                          String password = 'b1st1bo1';

                          var login = inputState == LoginInputState.Login
                              ? await ApiPost.login(
                                  username: username, password: password)
                              : await ApiPost.register(
                                  username: username, password: password);

                          if (login.errorMessage != null)
                            _showMyDialog(login.errorMessage);
                          else
                            widget.onLoggedIn(login.data);

                          // if (formKey.currentState.validate()) {
                          //   // _showMyDialog();
                          //   String username = usernameKey.currentState.value;
                          //   String password = passKey.currentState.value;

                          //   var login = inputState == LoginInputState.Login
                          //       ? await ApiPost.login(
                          //           username: username, password: password)
                          //       : await ApiPost.register(
                          //           username: username, password: password);

                          //   if (login.errorMessage != null)
                          //     _showMyDialog(login.errorMessage);
                          //   else
                          //     widget.onLoggedIn(login.data);
                          // }
                        },
                        child: Text('OK'),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      )),
    );
  }

  setInputState(LoginInputState state) {
    setState(() => inputState = state);
  }

  Future<void> _showMyDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Fejl'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
