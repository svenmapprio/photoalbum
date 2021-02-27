import 'package:get_it/get_it.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/dialog_service.dart';
import 'package:photoalbum/services/share_service.dart';
import 'package:photoalbum/services/state_service.dart';

GetIt locator = GetIt();

void setupLocator() {
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => ShareService());
  locator.registerLazySingleton(() => DataService());
  locator.registerLazySingleton(() => StateService());
}
