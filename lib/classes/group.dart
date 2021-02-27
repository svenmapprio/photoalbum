import 'package:rxdart/rxdart.dart';

import '../api.dart';

class Group {
  List<AlbumRow> albums = [];
  int id = 0;
  String name = '';

  Group(BehaviorSubject<GroupRow> row) {
    row.listen(setFromRow);
  }

  void setFromRow(GroupRow row) {
    this.id = row?.id ?? 0;
    this.name = row?.name ?? '';
  }
}
