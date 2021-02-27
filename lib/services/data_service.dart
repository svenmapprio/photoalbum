import 'dart:developer';
import 'dart:io';

import 'package:photoalbum/classes/album.dart';
import 'package:photoalbum/classes/group.dart';
import 'package:photoalbum/classes/user.dart';
import 'package:photoalbum/services/state_service.dart';
import 'package:rxdart/rxdart.dart';

import '../api.dart';
import '../locator.dart';
import 'dialog_service.dart';

class DataService {
  final BehaviorSubject<UserCompositeRow> userRow =
      BehaviorSubject<UserCompositeRow>().startWith(null);
  final BehaviorSubject<GroupRow> groupRow =
      BehaviorSubject<GroupRow>().startWith(null);
  final BehaviorSubject<AlbumRow> albumRow =
      BehaviorSubject<AlbumRow>().startWith(null);

  final BehaviorSubject<List<UserRow>> users =
      BehaviorSubject<List<UserRow>>().startWith([]);
  final BehaviorSubject<List<GroupRow>> groups =
      BehaviorSubject<List<GroupRow>>().startWith([]);
  final BehaviorSubject<List<GroupRow>> searchGroups =
      BehaviorSubject<List<GroupRow>>().startWith([]);

  final BehaviorSubject<List<AlbumCompositeRow>> albums =
      BehaviorSubject<List<AlbumCompositeRow>>().startWith([]);
  final BehaviorSubject<List<PhotoCompositeRow>> photos =
      BehaviorSubject<List<PhotoCompositeRow>>().startWith([]);
  final BehaviorSubject<List<MediaCompositeRow>> media =
      BehaviorSubject<List<MediaCompositeRow>>().startWith([]);

  User user;
  Group group;
  Album album;

  HttpClientRequest searchGroupsRequest;

  DataService() {
    user = User(userRow);
    group = Group(groupRow);
    album = Album(albumRow);

    userRow.listen((row) async {
      if (row != null && row.id > 0) {
        var groupsRes = await ApiGet.group();
        groups.add(groupsRes.data);
      }
    });

    groupRow.listen((row) async {
      if (row != null && row.id > 0) {
        var usersRes = await ApiGet.user(row.id, UserGroupStatus.Accepted);

        users.add(usersRes.data);

        var albumsRes = await ApiGet.album(row.id);

        albums.add(albumsRes.data);
      }
    });

    albumRow.listen((row) async {
      if (row != null && row.id > 0) {
        var mediaRes = await ApiGet.media(row.id);
        media.add(mediaRes.data);
      }
    });

    groups.listen((groups) {
      if (groups.length > 0 && groupRow.value == null) {
        groupRow.add(groups.first);
      }
    });

    _stateService.groupNameLike.listen((nameLike) async {
      if (searchGroupsRequest != null) {
        searchGroupsRequest.abort();
        searchGroupsRequest = null;
      }

      List<GroupRow> _searchGroups;

      if (nameLike?.isNotEmpty == true && nameLike.length > 2) {
        var groupsRes = await ApiGet.group(nameLike: nameLike);
        if (groupsRes.success) _searchGroups = groupsRes.data;
      }

      _searchGroups ??= [];

      searchGroups.add(_searchGroups.sublist(0));
    });
  }

  StateService _stateService = locator<StateService>();

  DialogService _dialogService = locator<DialogService>();

  Future<void> addGroup() async {
    String name =
        await _dialogService.getInput(label: 'Navn', title: 'Ny gruppe');

    var createRes = await ApiPut.group(name: name);

    if (createRes.success) {
      var groupInstanceRes = await ApiGet.groupInstance(createRes.data.pk);
      if (groupInstanceRes.success) groupRow.add(groupInstanceRes.data);

      var groupsRes = await ApiGet.group();

      if (groupsRes.success) groups.add(groupsRes.data);
    }
  }

  Future<void> addAlbum() async {
    var name = await locator<DialogService>()
        .getInput(title: 'Nyt album', label: 'Navn');

    var createRes = await ApiPut.album(name: name, groupId: group.id);

    if (createRes.success) {
      // var albumInstanceRes = await ApiGet.albumInstance(createRes.data.pk);

      // if (albumInstanceRes.success) albumRow.add(albumInstanceRes.data);

      var albumRes = await ApiGet.album(group.id);

      if (albumRes.success) albums.add(albumRes.data);
    }
  }

  Future<void> renameAlbum() async {
    var row = albumRow.value;
    var name = await locator<DialogService>()
        .getInput(label: 'Navn', title: 'Omdøb album');
    row.name = name;

    var patchRes = await ApiPatch.album(row);

    if (patchRes.success) {
      albumRow.add(row);
      var _albums = albums.value;
      var index = _albums.indexOf(row);
      _albums[index] = row;
      albums.add(_albums);
    }
  }

  Future<void> renameGroup() async {
    var row = groupRow.value;
    var name = await locator<DialogService>()
        .getInput(label: 'Navn', title: 'Omdøb album');
    row.name = name;

    var patchRes = await ApiPatch.group(row);

    if (patchRes.success) {
      groupRow.add(row);
      var _groups = groups.value;
      var index = _groups.indexOf(row);
      _groups[index] = row;
      groups.add(_groups);
    }
  }

  Future<void> deleteMedia(MediaCompositeRow row) async {
    var deleteRes = await ApiDelete.media(row.id, row.type, row.postId);

    if (deleteRes.success) {
      var albumRes = await ApiGet.album(group.id);
      if (albumRes.success) albums.add(albumRes.data);

      var mediaRes = await ApiGet.media(album.id);
      if (mediaRes.success) media.add(mediaRes.data);
    }
  }

  Future<void> deletePhoto(PhotoCompositeRow row) async {
    var deleteRes = await ApiDelete.photo(row.id, row.postId);
    if (deleteRes.success) {
      var albumRes = await ApiGet.album(group.id);
      if (albumRes.success) albums.add(albumRes.data);

      var photosRes = await ApiGet.photo(album.id);
      if (photosRes.success) photos.add(photosRes.data);
    }
  }
}
