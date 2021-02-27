import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

class StateService {
  registerTabController(TickerProvider vsync) {
    tabController = TabController(length: 3, initialIndex: 0, vsync: vsync);

    tabController.addListener(_listenTabIndex);
  }

  _listenTabIndex() {
    tabIndex.add(tabController.index);
  }

  disposeTabController() {
    tabController.removeListener(_listenTabIndex);
    tabController.dispose();
  }

  var startPageScaffold = GlobalKey<ScaffoldState>();
  TabController tabController;
  var tabIndex = BehaviorSubject<int>();

  get userTabActive => tabIndex.value == 0;
  get groupTabActive => tabIndex.value == 1;
  set groupTabActive(bool v) => tabController.animateTo(1);
  get socialTabActive => tabIndex.value == 2;

  BehaviorSubject<bool> tokenChecked = BehaviorSubject<bool>().startWith(false);

  BehaviorSubject<int> bottomNavIndex = BehaviorSubject<int>().startWith(1);

  BehaviorSubject<bool> userEditActive =
      BehaviorSubject<bool>().startWith(false);

  BehaviorSubject<bool> groupSearchActive =
      BehaviorSubject<bool>().startWith(false);

  BehaviorSubject<String> groupNameLike =
      BehaviorSubject<String>().startWith(null);
}
