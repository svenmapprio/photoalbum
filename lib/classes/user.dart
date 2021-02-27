import 'package:rxdart/rxdart.dart';

import '../api.dart';

class User {
  int id = 0;
  String username = '';

  User(BehaviorSubject<UserRow> row) {
    row.listen(setFromRow);
  }

  void setFromRow(UserRow row) {
    this.id = row?.id ?? 0;
    this.username = row?.name ?? '';

    if (row != null) {}
  }
}
