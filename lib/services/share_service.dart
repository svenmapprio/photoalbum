import 'dart:async';
import 'dart:developer';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/rxdart.dart';
import '../api.dart';

class ShareService {
  final media = BehaviorSubject<List<SharedMediaFile>>();

  ShareService() {
    ReceiveSharingIntent.getInitialMedia().then((value) {
      media.add(value);
    });

    ReceiveSharingIntent.getMediaStream().listen((value) => media.add(value));
  }

  StreamSubscription _intentDataStreamSubscription;

  void dispose() {
    media.close();
    _intentDataStreamSubscription.cancel();
  }

  var selectedShareAlbums = new BehaviorSubject<List<AlbumRow>>();

  void addAlbum(AlbumRow albumRow) {
    var albums = selectedShareAlbums.value ?? [];
    if (albums.indexOf(albumRow) == -1) albums.add(albumRow);

    selectedShareAlbums.add(albums);
  }

  void removeAlbum(AlbumRow albumRow) {
    var albums = selectedShareAlbums.value ?? [];
    albums.remove(albumRow);

    selectedShareAlbums.add(albums);
  }
}
