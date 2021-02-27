import 'dart:developer';
import 'dart:io';

import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/share_service.dart';
import 'package:photoalbum/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

import '../locator.dart';
import '../api.dart';
import '../services/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class DialogManager extends StatefulWidget {
  final Widget child;
  DialogManager({Key key, this.child}) : super(key: key);
  _DialogManagerState createState() => _DialogManagerState();
}

class _DialogManagerState extends State<DialogManager> {
  DialogService _dialogService = locator<DialogService>();
  @override
  void initState() {
    super.initState();
    _dialogService.registerInputDialogListener(_showInputDialog);
    _dialogService.registerShareDialogListener(_showShareDialog);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _show(Widget dialog) {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: '',
      useRootNavigator: true,
      barrierDismissible: true,
      pageBuilder: (context, anim1, anim2) {},
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            child: dialog,
            opacity: anim1.value,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 150),
    );
  }

  final _shareService = locator<ShareService>();
  final _dataService = locator<DataService>();
  final BehaviorSubject<List<BehaviorSubject<double>>> _currentUploads =
      BehaviorSubject<List<BehaviorSubject<double>>>().startWith([]);

  void _showShareDialog() {
    var albumIdSet = _dataService.albumRow?.value != null &&
        _dataService.albumRow.value.id > 0;
    var selectedShareAlbumsSet =
        _shareService.selectedShareAlbums.value != null &&
            _shareService.selectedShareAlbums.value.length > 0;

    var dialog = AlertDialog(
      title: Text('Upload af billeder'),
      content: StreamBuilder(
          stream: _currentUploads.stream,
          initialData: <BehaviorSubject<double>>[],
          builder: ((context,
              AsyncSnapshot<List<BehaviorSubject<double>>> snapshot) {
            if (snapshot.data.length > 0) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder(
                          stream: snapshot.data[index].stream,
                          initialData: 0.0,
                          builder: (context, AsyncSnapshot<double> snapshot) {
                            var indicator = LinearProgressIndicator(
                              minHeight: 30,
                              value: snapshot.data,
                            );
                            var container = Container(
                              margin: EdgeInsets.all(5.0),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0))),
                              child: indicator,
                            );
                            return container;
                          },
                        );
                      },
                    ),
                  )
                ],
              );
            } else if (albumIdSet) {
              return Text('Upload til dette album?');
            } else {
              return StreamBuilder(
                stream: _shareService.selectedShareAlbums.stream,
                builder: (context, AsyncSnapshot<List<AlbumRow>> snapshot) {
                  return selectedShareAlbumsSet
                      ? Column(
                          children: [
                            Text(
                              'Billederne vil blive uploaded til',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: snapshot.data?.length ?? 0,
                                itemBuilder: (context, index) {
                                  var albumRow = snapshot.data[index];
                                  var tile = ListTile(
                                      leading: IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () {
                                          _shareService.removeAlbum(albumRow);
                                        },
                                      ),
                                      title: Text(albumRow.name));

                                  var container = Container(
                                    child: tile,
                                  );

                                  return container;
                                },
                              ),
                            ),
                          ],
                        )
                      : Text('Der skal vælges mindst ét album til upload.');
                },
              );
            }
          })),
      actions: [
        TextButton(
          child: Text('Annuller'),
          onPressed: () async {
            _shareService.media.add(null);

            ReceiveSharingIntent.reset();

            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
        albumIdSet || selectedShareAlbumsSet
            ? TextButton(
                child: Text('Ok'),
                onPressed: () async {
                  var files = List.from(_shareService.media.value);

                  // var failedFiles = <SharedMediaFile>[];
                  var uploadsTmp = List(files.length)
                      .map<BehaviorSubject<double>>(
                          (_) => BehaviorSubject<double>())
                      .toList();

                  _currentUploads.add(uploadsTmp);

                  List<AlbumRow> albumRows = _dataService.albumRow.value != null
                      ? [_dataService.albumRow.value]
                      : _shareService.selectedShareAlbums.value;
                  var albumIds = albumRows.map((row) => row.id).toList();
                  var postIds = <int>[];

                  if (albumIds != null && albumIds.length > 0) {
                    for (int i = 0; i < albumIds.length; i++) {
                      var albumId = albumIds[i];
                      var putRes = await ApiPut.post(albumId: albumId);
                      if (putRes.success) postIds.add(putRes.data.pk);
                    }

                    for (int i = 0; i < files.length; i++) {
                      var smf = files[i];
                      var file = File(smf.path);
                      var size = await file.length();
                      var stream = file.openRead();

                      var mime = lookupMimeType(smf.path);
                      var mediaTypeString = mime.split('/')[0];
                      var mediaType = mediaTypeString == 'image'
                          ? MediaType.Photo
                          : mediaTypeString == 'video'
                              ? MediaType.Video
                              : throw 'unknown mediatype';

                      var format = path.extension(smf.path).substring(1);
                      var duration = 0;
                      if (mediaType == MediaType.Video) {
                        var controller = VideoPlayerController.file(file);
                        await controller.initialize();
                        duration = controller.value.duration.inMilliseconds;
                      }

                      var mediaSaveRes = mediaType == MediaType.Photo
                          ? await ApiPut.photo(
                              postIds: postIds, format: format, size: size)
                          : await ApiPut.video(
                              postIds: postIds,
                              format: format,
                              size: size,
                              duration: duration);

                      if (mediaSaveRes.success && mediaSaveRes.data.pk > 0) {
                        var mediaUploadRes = mediaType == MediaType.Photo
                            ? ApiUpload.photo(
                                stream, format, size, mediaSaveRes.data.pk)
                            : ApiUpload.video(
                                stream, format, size, mediaSaveRes.data.pk);

                        uploadsTmp[i] = mediaUploadRes.progress;

                        _currentUploads.add(uploadsTmp);

                        await mediaUploadRes.done;
                      }
                    }
                  }

                  _dataService.groupRow.add(_dataService.groupRow.value);
                  _shareService.selectedShareAlbums.add([]);

                  // _shareService.media.add(null);

                  // ReceiveSharingIntent.reset();

                  Navigator.of(context, rootNavigator: true).pop();
                },
              )
            : TextButton(
                child: Text('Opret album'),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  _dataService.addAlbum();
                },
              ),
      ],
    );
    // content: StreamBuilder(stream: _shareService.media.stream, initialData: <SharedMediaFile>[],));

    _show(dialog);
  }

  void _showInputDialog(
      {String title,
      String label = '',
      String validationText = 'Feltet må ikke være tomt'}) async {
    var formKey = GlobalKey<FormState>();
    var inputKey = GlobalKey<FormFieldState>();
    var dialogKey = GlobalKey<State>();

    var dialog = AlertDialog(
      key: dialogKey,
      title: title != null ? Text(title) : null,
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    key: inputKey,
                    decoration: InputDecoration(
                        labelText: label,
                        floatingLabelBehavior: FloatingLabelBehavior.auto),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Feltet må ikke være tomt';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Ok'),
          onPressed: () async {
            if (formKey.currentState.validate()) {
              _dialogService.sendInput(inputKey.currentState.value);
              var nav = Navigator.of(context, rootNavigator: true);
              nav.pop();
            }
          },
        ),
      ],
    );

    _show(dialog);
  }
}
