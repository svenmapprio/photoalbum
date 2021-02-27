import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photoalbum/classes/group.dart';

import 'package:photoalbum/pages/album-details.dart';
import 'package:photoalbum/pages/group-details.dart';
import 'package:photoalbum/pages/social.dart';
import 'package:photoalbum/pages/user-details.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/dialog_service.dart';
import 'package:photoalbum/services/share_service.dart';
import 'package:photoalbum/services/state_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../locator.dart';
import '../widgets.dart';

class StartPage extends StatefulWidget {
  final Function onLoggedOut;

  StartPage({Key key, @required this.onLoggedOut}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StartPageState();
}

class StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  DataService _dataService = locator<DataService>();

  @override
  void initState() {
    super.initState();

    // _dataService.groupRow.listen((row) async {
    //   log('group row set, $row');
    //   _dataService.albumRow.add(null);

    //   setState(() {});
    // });

    // _shareService.media.listen((media) {
    //   setState(() {});
    // });
  }

  @override
  void dispose() {
    _stateService.disposeTabController();
    super.dispose();
  }

  var _stateService = locator<StateService>();

  var _shareService = locator<ShareService>();

  @override
  Widget build(BuildContext context) {
    var tabsBar = TabBar(
      controller: _stateService.tabController,
      labelColor: Theme.of(context).primaryColorDark,
      unselectedLabelColor: Theme.of(context).primaryColorLight,
      indicatorColor: Colors.transparent,
      labelPadding:
          EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top, 0, 0),
      tabs: [
        Tab(
          child: Icon(Icons.person),
        ),
        Tab(child: Icon(Icons.photo_album_rounded)),
        Tab(
          child: Icon(Icons.group_rounded),
        ),
      ],
    );

    var tabs = TabBarView(
      controller: _stateService.tabController,
      children: [UserDetailsPage(), GroupDetailsPage(), SocialPage()],
    );

    var scaffold = Scaffold(
      key: locator<StateService>().startPageScaffold,
      appBar: tabsBar,
      body: tabs,
    );

    return scaffold;
  }

  handleAddGroupTapped() {}
}
