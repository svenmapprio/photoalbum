import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/dialog_service.dart';
import 'package:photoalbum/services/share_service.dart';
import 'package:photoalbum/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/rxdart.dart';
import '../api.dart';
import '../locator.dart';

class AlbumDetailsStreamMap {
  final AlbumRow album;
  final List<MediaCompositeRow> media;
  final bool viewState;

  AlbumDetailsStreamMap(DataService dataService, this.viewState)
      : album = dataService.albumRow.value,
        media = dataService.media.value;
}

enum AlbumMenuAction { Rename }

class AlbumDetailsPage extends StatefulWidget {
  AlbumDetailsPageState createState() => AlbumDetailsPageState();
}

class AlbumDetailsPageState extends State<AlbumDetailsPage> {
  BehaviorSubject<AlbumDetailsStreamMap> _stream =
      BehaviorSubject<AlbumDetailsStreamMap>();

  BehaviorSubject<bool> _viewState = BehaviorSubject<bool>();

  void _listen(_) {
    _stream.add(AlbumDetailsStreamMap(_dataService, _viewState.value));
  }

  @override
  void initState() {
    super.initState();

    _dataService.albumRow.listen(_listen);
    _dataService.photos.listen(_listen);
    _viewState.listen(_listen);
  }

  DataService _dataService = locator<DataService>();
  ShareService _shareService = locator<ShareService>();

  Widget build(BuildContext context) {
    Scaffold scaffold(AlbumDetailsStreamMap data) {
      Widget _grid() {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemCount: data.media?.length ?? 0,
          itemBuilder: (context, i) {
            MediaCompositeRow row = data.media[i];

            var thumbnail = Thumbnail(
              mediaId: row.id,
              type: row.type,
            );

            var button = GestureDetector(
              child: thumbnail,
              onTap: () {
                _viewState.add(true);
              },
            );

            return button;
          },
        );
      }

      Widget _card(MediaCompositeRow row) {
        var popupMenu = PopupMenuButton(
          icon: Icon(Icons.menu),
          onSelected: (PhotoMenuAction action) {
            if (action == PhotoMenuAction.Delete) _dataService.deleteMedia(row);
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<PhotoMenuAction>>[
            PopupMenuItem<PhotoMenuAction>(
                child: Text('Slet'), value: PhotoMenuAction.Delete)
          ],
        );

        //bruger
        var userRow = Row(
          children: [
            Icon(Icons.person),
            Text(row.creatorInfo.screenName),
            Visibility(
              child: popupMenu,
              visible: row.creatorInfo.id == _dataService.user.id,
            )
          ],
        );
        //billede
        var photo = row.type == MediaType.Photo
            ? PhotoView(photoId: row.id)
            : VideoView(videoId: row.id);
        //beskrivelse
        var description = Text(row.description ?? '');
        //vis kommentarer
        //dato
        var date = Text(row.created.toString());

        return Container(
          child: Column(
            children: [userRow, photo, description, date],
          ),
        );
      }

      Widget _list() {
        return ListView.builder(
          itemCount: data?.media?.length ?? 0,
          itemBuilder: (context, index) {
            return _card(data.media[index]);
          },
        );
      }

      Widget _body(bool viewState) {
        return viewState ? _list() : _grid();
      }

      var _scaffold = Scaffold(
          appBar: AppBar(
            actions: [
              if (data.album?.creator == _dataService.user.id)
                PopupMenuButton(
                  onSelected: ((AlbumMenuAction action) {
                    if (action == AlbumMenuAction.Rename)
                      _dataService.renameAlbum();
                  }),
                  icon: Icon(Icons.menu),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<AlbumMenuAction>>[
                    PopupMenuItem<AlbumMenuAction>(
                        child: Text('Omdøb'), value: AlbumMenuAction.Rename)
                  ],
                )
            ],
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                data?.viewState == true
                    ? _viewState.add(false)
                    : _dataService.albumRow.add(null);
              },
            ),
            backgroundColor: Colors.white,
            elevation: 0.0,
            title: RowStreamName(_dataService.albumRow),
          ),
          body: data != null ? _body(data.viewState == true) : Container());

      return _scaffold;
    }

    var sb = StreamBuilder(
      stream: _stream,
      builder: (context, AsyncSnapshot<AlbumDetailsStreamMap> snapshot) {
        return snapshot?.data != null ? scaffold(snapshot.data) : Container();
      },
    );

    return sb;
  }
}

enum PhotoMenuAction { Delete }
