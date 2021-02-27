import 'package:rxdart/rxdart.dart';

import '../api.dart';

class Album {
  int id = 0;
  String name = '';
  List<int> preview = [];

  Album(BehaviorSubject<AlbumRow> row) {
    row.listen(setFromRow);
  }

  void setFromRow(AlbumRow row) {
    this.id = row?.id ?? 0;
    this.name = row?.name ?? '';
  }
}
