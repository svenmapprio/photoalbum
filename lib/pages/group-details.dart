import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photoalbum/classes/group.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/dialog_service.dart';
import 'package:photoalbum/services/share_service.dart';
import 'package:photoalbum/services/state_service.dart';
import 'package:photoalbum/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/streams.dart';

import '../api.dart';
import '../locator.dart';

class GroupDetailsStreamMap {
  final List<UserRow> users;
  final List<AlbumCompositeRow> albums;
  final GroupRow groupRow;

  GroupDetailsStreamMap(DataService dataService)
      : users = dataService.users.value,
        albums = dataService.albums.value,
        groupRow = dataService.groupRow.value;
}

class GroupDetailsPage extends StatefulWidget {
  @override
  GroupDetailsPageState createState() => GroupDetailsPageState();
}

class GroupDetailsPageState extends State<GroupDetailsPage>
    with SingleTickerProviderStateMixin {
  DataService _dataService = locator<DataService>();
  ShareService _shareService = locator<ShareService>();

  var _stream = BehaviorSubject<GroupDetailsStreamMap>();

  void _listen(_) {
    _stream.add(GroupDetailsStreamMap(_dataService));
  }

  void initState() {
    super.initState();

    _stateService.registerTabController(this);

    _dataService.users.listen(_listen);
    _dataService.albums.listen(_listen);
    _dataService.groupRow.listen(_listen);
  }

  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      body: StreamBuilder(
        stream: _stream,
        builder: (context, AsyncSnapshot<GroupDetailsStreamMap> snapshot) {
          var decoration = BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                spreadRadius: 0,
                blurRadius: 4,
              ),
            ],
          );

          Widget groupHeader(BuildContext context) {
            var row = Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Albummer', style: TextStyle(fontWeight: FontWeight.bold)),
                InlineButton(_dataService.addAlbum)
              ],
            );

            var container = Container(
              padding: EdgeInsets.all(20.0),
              child: row,
            );

            return container;
          }

          Widget groupTile(BuildContext context, int index) {
            double jitter(double input, double degree) =>
                input *
                    (0.5 + (math.Random().nextInt(100) / 100) * degree / 2) +
                input * (0.5 - (math.Random().nextInt(100) / 100) * degree / 2);
            var album = snapshot.data.albums[index];

            var length = album.preview?.length ?? 0;
            var rowHeight = 120.0;
            var rowWidth = 120.0;
            var thumbnailHeight = 60.0;
            var spreadWidth = 20.0;

            var centerOffset = ((rowHeight - thumbnailHeight) / 2.0);
            var previewImages = <Positioned>[];
            var step = length == 2 ? 180.0 : 120.0;

            for (int i = 0; i < length; i++) {
              var angleOffset = length == 3 ? 50.0 : 65.0;

              var image = Thumbnail.fromPreview(album.preview[i],
                  height: thumbnailHeight);

              if (length > 1) {
                var angle = (jitter(step, 0.0) * i) + jitter(angleOffset, 0.0);
                var angleRad = math.pi * angle / 180.0;

                var y = math.sin(angleRad) * spreadWidth;
                var x = math.cos(angleRad) * spreadWidth;

                previewImages.add(Positioned(
                    child: Container(
                      clipBehavior: Clip.none,
                      child: image,
                      decoration: decoration,
                    ),
                    top: jitter(centerOffset, 0.0) - y,
                    left: centerOffset - x));
              } else {
                previewImages.add(Positioned(
                  top: centerOffset,
                  left: centerOffset,
                  child: Container(
                    child: image,
                    decoration: decoration,
                  ),
                ));
              }
            }

            var previewWrap = StreamBuilder(
              stream: _shareService.media,
              builder:
                  (context, AsyncSnapshot<List<SharedMediaFile>> snapshot) {
                if (snapshot.data != null && snapshot.data.length > 0) {
                  var sb = StreamBuilder(
                    builder: (context, snapshot) {
                      var checkbox = Checkbox(
                        onChanged: (checked) {
                          checked
                              ? _shareService.addAlbum(album)
                              : _shareService.removeAlbum(album);
                        },
                        value: snapshot.data != null &&
                            snapshot.data.indexOf(album) != -1,
                      );

                      var transform = Transform.scale(
                        scale: 1.5,
                        child: checkbox,
                      );

                      var container = Container(
                        // height: rowHeight,
                        // width: rowWidth,

                        child: transform,
                      );
                      return container;
                    },
                    stream: _shareService.selectedShareAlbums.stream,
                  );
                  var positioned = Positioned(child: sb, right: 0);

                  previewImages.add(positioned);
                }

                return Container(
                    height: rowHeight,
                    width: rowWidth,
                    child: Stack(
                      children: previewImages,
                    ));
              },
            );

            var container = Container(
                padding: EdgeInsets.all(10.0),
                height: rowHeight,
                child: Row(
                  children: [
                    previewWrap,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(album.name,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        if (album.description?.isNotEmpty == true)
                          Text(album.description)
                      ],
                    )
                  ],
                ));

            var tappable = InkWell(
                onTap: () {
                  _dataService.albumRow.add(album);
                },
                child: Ink(
                  height: rowHeight + 20,
                  child: container,
                ));

            return tappable;
          }

          var group = ListView.builder(
            itemCount: (snapshot.data?.albums?.length ?? 0) + 1,
            itemBuilder: (context, i) {
              // return groupTile(context, i);
              return i == 0 ? groupHeader(context) : groupTile(context, i - 1);
            },
          );

          var tabsBar = TabBar(
            controller: _stateService.tabController,
            labelColor: Theme.of(context).primaryColorDark,
            unselectedLabelColor: Theme.of(context).primaryColorLight,
            indicatorColor: Colors.transparent,
            // labelPadding: EdgeInsets.fromLTRB(
            //     0, MediaQuery.of(context).padding.top, 0, 0),
            tabs: [
              Tab(
                child: Icon(Icons.photo_album),
              ),
              Tab(
                child: Icon(Icons.chat_bubble),
              ),
              Tab(child: Icon(Icons.group))
            ],
          );

          var social = Container(
            child: Text(''),
          );

          Widget membersHeader() {
            var row = Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medlemmer',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            );

            var container = Container(
              padding: EdgeInsets.all(20.0),
              child: row,
            );

            return container;
          }

          Widget membersTile(int index) {
            var user = snapshot.data?.users[index];
            print(user.name);
            return ListTile(
                leading: Icon(Icons.person), title: Text(user.name));
          }

          var members = ListView.builder(
            itemCount: (snapshot.data?.users?.length ?? 0) + 1,
            itemBuilder: (context, index) {
              return index == 0 ? membersHeader() : membersTile(index - 1);
            },
          );

          var tabs = TabBarView(
            controller: _stateService.tabController,
            children: [group, social, members],
          );

          var scaffold = Scaffold(
            key: locator<StateService>().startPageScaffold,
            appBar: AppBar(
              actions: [
                if (snapshot.data != null &&
                    snapshot.data.groupRow.creator == _dataService.user.id)
                  PopupMenuButton(
                    icon: Icon(Icons.menu),
                    onSelected: (GroupMenuAction action) {
                      if (action == GroupMenuAction.Rename)
                        _dataService.renameGroup();
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<GroupMenuAction>>[
                      PopupMenuItem<GroupMenuAction>(
                          child: Text('Omdøb'), value: GroupMenuAction.Rename)
                    ],
                  )
              ],
              backgroundColor: Theme.of(context).cardColor,
              elevation: 0.2,
              bottom: tabsBar,
              automaticallyImplyLeading: false,
              title: Text(
                  snapshot.data != null ? snapshot.data.groupRow.name : ''),
            ),
            body: tabs,
          );

          return scaffold;
        },
      ),
    );

    return scaffold;
  }

  var _stateService = locator<StateService>();
}

enum GroupMenuAction { Rename }
