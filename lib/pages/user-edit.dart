import 'package:flutter/material.dart';
import 'package:photoalbum/api.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/state_service.dart';

import '../locator.dart';

class UserEditPage extends StatefulWidget {
  @override
  UserEditPageState createState() => UserEditPageState();
}

class UserEditPageState extends State<UserEditPage> {
  var _dataService = locator<DataService>();
  var _stateService = locator<StateService>();
  var formKey = GlobalKey<FormState>();
  var nameKey = GlobalKey<FormFieldState>();
  var screenNameKey = GlobalKey<FormFieldState>();
  var emailKey = GlobalKey<FormFieldState>();

  Widget build(BuildContext context) {
    var row = _dataService.userRow.value;

    var form = Form(
      key: formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 75.0,
              )
            ],
          ),
          TextFormField(
            key: nameKey,
            initialValue: row.name,
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
            key: screenNameKey,
            initialValue: row.screenName,
            decoration: const InputDecoration(
                labelText: 'Navn til visning',
                floatingLabelBehavior: FloatingLabelBehavior.auto),
            validator: (value) {
              return null;
            },
          ),
          TextFormField(
            key: emailKey,
            initialValue: row.email,
            decoration: const InputDecoration(
                labelText: 'Email',
                floatingLabelBehavior: FloatingLabelBehavior.auto),
            validator: (value) {
              return null;
            },
          ),
        ],
      ),
    );

    var scaffold = Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.0,
          title: Text('Profil'),
          actions: [
            IconButton(icon: Icon(Icons.done), onPressed: _save),
          ],
          automaticallyImplyLeading: false,
          leading: IconButton(icon: Icon(Icons.close), onPressed: _close)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.0),
        child: form,
      ),
    );

    return scaffold;
  }

  void _save() async {
    if (formKey.currentState.validate()) {
      var row = _dataService.userRow.value;
      row.name = nameKey.currentState.value;
      row.screenName = screenNameKey.currentState.value;

      if (row.screenName == '') row.screenName = null;

      row.email = emailKey.currentState.value;

      if (row.email == '') row.email = null;

      await ApiPatch.user(row);

      _close();
    }
  }

  void _close() {
    _stateService.userEditActive.add(false);
  }
}
