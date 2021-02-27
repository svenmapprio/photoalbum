import '../api.dart';

abstract class TableInstance {
  int id;
  String name;

  void setFromRow(TableInstanceRow row) {}
}
