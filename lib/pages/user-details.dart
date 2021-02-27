import 'package:flutter/material.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/dialog_service.dart';
import 'package:photoalbum/services/state_service.dart';

import '../locator.dart';
import '../api.dart';

class UserDetailsPage extends StatefulWidget {
  @override
  UserDetailsPageState createState() => UserDetailsPageState();
}

class UserDetailsPageState extends State<UserDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserInfo(),
        // Container(
        //   margin: EdgeInsets.fromLTRB(30.0, 0, 0, 15.0),
        //   child: Text(
        //     'Grupper',
        //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
        //   ),
        // ),
        // Expanded(
        //   child: GroupStreamList(),
        // )
      ],
    ));
  }
}

class UserInfo extends StatefulWidget {
  @override
  UserInfoState createState() => UserInfoState();
}

class UserInfoState extends State<UserInfo> {
  var _dataService = locator<DataService>();
  var _stateService = locator<StateService>();

  String _capitalizeWord(String word) {
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  String _capitalizeString(String s) {
    var words = s.trim().split(" ");

    return words.map(_capitalizeWord).join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _dataService.userRow,
        builder: (context, AsyncSnapshot<UserCompositeRow> snapshot) {
          if (snapshot.data != null) {
            var row = snapshot.data;
            var nameStyle =
                TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);
            var name = row.screenName ?? row.name;

            var nameText = Text(
              _capitalizeString(name),
              style: nameStyle,
            );

            var labelStyle =
                TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold);

            var container = Container(
                margin: EdgeInsets.fromLTRB(
                    30, MediaQuery.of(context).padding.top + 20, 30, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [nameText],
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 15),
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                          decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(100))),
                          child: Icon(
                            Icons.person,
                            size: 75.0,
                          ),
                        ),
                        Column(
                          children: [
                            Text('Billeder', style: labelStyle),
                            Text(row.photoCount.toString(),
                                style: TextStyle(fontSize: 14.0))
                          ],
                        ),
                        Column(
                          children: [
                            Text('Videor', style: labelStyle),
                            Text(row.videoCount.toString(),
                                style: TextStyle(fontSize: 14.0))
                          ],
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                            child: OutlineButton(
                          color: Colors.white,
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          textColor: Theme.of(context).primaryColor,
                          child: Text('Rediger profil'),
                          onPressed: () {
                            _stateService.userEditActive.add(true);
                          },
                        )),
                      ],
                    )
                  ],
                ));

            return container;
          } else
            return Container(height: 0, width: 0);
        });
  }
}
