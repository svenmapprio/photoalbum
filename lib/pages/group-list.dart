import 'package:flutter/material.dart';
import 'package:photoalbum/classes/user.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/state_service.dart';
import 'package:photoalbum/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../api.dart';
import '../locator.dart';

class GroupListPage extends StatefulWidget {
  @override
  GroupListPageState createState() => GroupListPageState();
}

class GroupListPageState extends State<GroupListPage> {
  var _stateService = locator<StateService>();
  var _dataService = locator<DataService>();

  @override
  Widget build(BuildContext context) {
    var sb = StreamBuilder(
        stream: _stateService.groupSearchActive.stream,
        builder: (context, AsyncSnapshot<bool> snapshot) {
          return snapshot.data == true
              ? GroupStreamList(_dataService.searchGroups, () {
                  var searchField = TextFormField(
                    onChanged: (value) {
                      _stateService.groupNameLike.add(value);
                    },
                    initialValue: _stateService.groupNameLike.value,
                    decoration: const InputDecoration(
                        labelText: 'Navn',
                        floatingLabelBehavior: FloatingLabelBehavior.auto),
                    validator: (value) {
                      return null;
                    },
                  );

                  var row = Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_backspace),
                        onPressed: () {
                          _stateService.groupNameLike.add(null);
                          _stateService.groupSearchActive.add(false);
                        },
                      ),
                      Expanded(
                        child: searchField,
                      ),
                    ],
                  );

                  var container = Container(
                    padding: EdgeInsets.all(20.0),
                    child: row,
                  );

                  return container;
                })
              : GroupStreamList(_dataService.groups, () {
                  return Container(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dine grupper',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.0),
                          ),
                          Row(
                            children: [
                              InlineButton(_dataService.addGroup),
                              InlineButton(() {
                                _stateService.groupNameLike.add(null);
                                _stateService.groupSearchActive.add(true);
                              }, text: 'Søg', icon: Icons.search)
                            ],
                          )
                        ],
                      ));
                });
        });

    return sb;
  }
}

class GroupListStreamMap {
  final List<GroupRow> groups;

  GroupListStreamMap(this.groups);
}

class GroupStreamList extends StatefulWidget {
  final BehaviorSubject<List<GroupRow>> _groups;
  final Widget Function() _header;

  GroupStreamList(this._groups, this._header);

  @override
  GroupStreamListState createState() => GroupStreamListState();
}

class GroupStreamListState extends State<GroupStreamList> {
  var _dataService = locator<DataService>();
  var _stateService = locator<StateService>();

  var _stream = BehaviorSubject<GroupListStreamMap>();
  void _listen(_) {
    _stream.add(GroupListStreamMap(widget._groups.value));
  }

  @override
  void initState() {
    super.initState();

    widget._groups.listen(_listen);
  }

  // @override
  // void dispose() {
  //   super.dispose();

  //   widget._groups.
  // }

  @override
  Widget build(BuildContext context) {
    Widget build(List<GroupRow> groups) {
      return ListView.builder(
          itemCount: (groups?.length ?? 0) + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return widget._header();
            } else {
              var groupIndex = i - 1;
              var group = groups[groupIndex];

              var groupSelected = _dataService.group.id == group.id;

              var textColor = groupSelected
                  ? Theme.of(context).primaryColor
                  : Colors.black87;

              var fontWeight =
                  groupSelected ? FontWeight.bold : FontWeight.normal;

              var style = TextStyle(
                  fontSize: 16.0, color: textColor, fontWeight: fontWeight);

              var statusIcon = group.status == UserGroupStatus.Accepted
                  ? Icons.done
                  : group.status == UserGroupStatus.Requested
                      ? Icons.arrow_forward
                      : Icons.add;

              var statusText = group.status == UserGroupStatus.Accepted
                  ? 'Medlem'
                  : group.status == UserGroupStatus.Requested
                      ? 'Anmodet'
                      : 'Anmod';

              BehaviorSubject<List<int>> disabledButtons =
                  BehaviorSubject<List<int>>().startWith([]);

              var tile = Container(
                  margin: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                  decoration: BoxDecoration(
                      // color: backgroundColor,
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  child: StreamBuilder(
                      stream: disabledButtons.stream,
                      builder: (context, AsyncSnapshot<List<int>> snapshot) {
                        return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                child: Text(group.name, style: style),
                                onPressed: () {
                                  if (group.status ==
                                      UserGroupStatus.Accepted) {
                                    _dataService.groupRow.add(group);

                                    _stateService.bottomNavIndex.add(1);
                                  }
                                },
                              ),
                              Visibility(
                                  visible:
                                      group.status != UserGroupStatus.Accepted,
                                  child: Opacity(
                                      opacity: disabledButtons.value
                                                  ?.indexOf(groupIndex) ==
                                              -1
                                          ? 1.0
                                          : 0.5,
                                      child: InlineButton(() async {
                                        List<int> disabledIndices =
                                            disabledButtons.value;
                                        if (disabledButtons.value
                                                .indexOf(groupIndex) ==
                                            -1) {
                                          disabledIndices.add(groupIndex);
                                          disabledButtons.add(disabledIndices);
                                          await _groupTabbed(groupIndex);
                                          disabledIndices.remove(groupIndex);
                                          disabledButtons.add(disabledIndices);
                                        }
                                      }, icon: statusIcon, text: statusText)))
                            ]);
                      }));

              return tile;
            }
          });
    }

    return StreamBuilder(
      stream: widget._groups.stream,
      builder: (context, AsyncSnapshot<List<GroupRow>> snapshot) {
        return snapshot.data != null ? build(snapshot.data) : Container();
      },
    );
  }

  Future<void> _groupTabbed(int groupIndex) async {
    var groups = _dataService.searchGroups.value.sublist(0);
    if (groups.length > groupIndex) {
      var userId = _dataService.user.id;
      var group = groups[groupIndex];
      var newStatus = group.status == UserGroupStatus.Requested
          ? UserGroupStatus.None
          : UserGroupStatus.Requested;

      await ApiPost.groupStatus(
          userId: userId, status: newStatus, groupId: group.id);

      group.status = newStatus;
      groups[groupIndex] = group;
      _dataService.searchGroups.add(groups);
    }
  }
}
