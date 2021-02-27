import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:photoalbum/locator.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'classes/summary.dart';

abstract class TableInstanceRow {
  int id;
  String name;
  int creator;

  TableInstanceRow(Map<String, dynamic> data)
      : id = data['id'],
        name = data['name'],
        creator = data['creator'];

  Map<String, dynamic> serialize() {
    return {'id': id, 'name': name, 'creator': creator};
  }
}

class UserRow extends TableInstanceRow {
  String screenName;
  String pwh;
  String email;

  UserRow(Map<String, dynamic> data)
      : screenName = data['screenName'] ?? data['name'],
        pwh = data['pwh'],
        email = data['email'],
        super(data);

  @override
  Map<String, dynamic> serialize() {
    var mapBase = super.serialize();
    mapBase['screenName'] = screenName;
    mapBase['pwh'] = pwh;
    return mapBase;
  }
}

class UserCompositeRow extends UserRow {
  final int photoCount;
  final int videoCount;

  UserCompositeRow(Map<String, dynamic> data)
      : photoCount = data['photoCount'],
        videoCount = data['videoCount'],
        super(data);
}

class GroupRow extends TableInstanceRow {
  UserGroupStatus status;

  GroupRow(Map<String, dynamic> data)
      : status = UserGroupStatus.values[data['status'] ?? 0],
        super(data);

  @override
  Map<String, dynamic> serialize() {
    var base = super.serialize();

    return base;
  }
}

class AlbumRow extends TableInstanceRow {
  String description;

  AlbumRow(Map<String, dynamic> data)
      : description = data['description'],
        super(data);

  @override
  Map<String, dynamic> serialize() {
    var base = super.serialize();

    base['description'] = description;

    return base;
  }
}

class AlbumPreview {
  final int videoId;
  final int photoId;

  AlbumPreview(Map<String, dynamic> data)
      : videoId = data['videoId'],
        photoId = data['photoId'];
}

class AlbumCompositeRow extends AlbumRow {
  final List<AlbumPreview> preview;
  AlbumCompositeRow(Map<String, dynamic> data)
      : preview =
            data['preview'].map<AlbumPreview>((o) => AlbumPreview(o)).toList(),
        super(data);
}

enum MediaType { Photo, Video }

class MediaCompositeRow {
  final UserRow creatorInfo;
  final int postId;
  final int id;
  final DateTime created;
  final String description;
  final int duration;
  final MediaType type;

  MediaCompositeRow(Map<String, dynamic> data)
      : id = data['id'],
        creatorInfo = UserRow(data['creatorInfo']),
        postId = data['postId'],
        type = MediaType.values[data['type']],
        description = data['description'],
        duration = data['duration'],
        created = DateTime.parse(data['created']).toLocal();
}

class PhotoRow {
  final int id;
  final String description;
  final DateTime created;

  PhotoRow(Map<String, dynamic> data)
      : id = data['id'],
        description = data['description'],
        created = DateTime.parse(data['created']).toLocal();

  Map<String, dynamic> serialize() {
    return {'id': id};
  }
}

class PhotoCompositeRow extends PhotoRow {
  final UserRow creatorInfo;
  final int postId;

  PhotoCompositeRow(Map<String, dynamic> data)
      : creatorInfo = UserRow(data['creatorInfo']),
        postId = data['postId'],
        super(data);
}

class LoginResponse {
  final String token;
  final UserCompositeRow user;
  LoginResponse(Map<String, dynamic> data)
      : token = data['token'],
        user = UserCompositeRow(data['user']);
}

class BoolResponse {
  final bool success;
  BoolResponse(Map<String, dynamic> data) : success = data['success'] ?? true;
}

class PrimaryKeyResponse {
  final int pk;
  PrimaryKeyResponse(Map<String, dynamic> data) : pk = data['pk'];
}

class ApiResponse<T> {
  T data;
  bool success;
  String errorMessage;
  String warningMessage;
  HttpClientRequest request;
  ApiResponse();
}

T getClass<T>(Type test, Map<String, dynamic> data) {
  T _class;
  String testStr = test.toString();

  switch (testStr) {
    case 'LoginResponse':
      _class = LoginResponse(data) as T;
      break;
    case 'PrimaryKeyResponse':
      _class = PrimaryKeyResponse(data) as T;
      break;
    case 'GroupRow':
      _class = GroupRow(data) as T;
      break;
    case 'AlbumRow':
      _class = AlbumRow(data) as T;
      break;
    case 'BoolResponse':
      _class = BoolResponse(data) as T;
      break;
    default:
      throw 'response missing implementation';
  }

  return _class;
}

List<T> getClassList<T>(Type test, List<dynamic> listData) {
  String testStr = test
      .toString()
      .replaceFirst('List', '')
      .replaceAll(new RegExp('[\<\>]'), '');

  switch (testStr) {
    case 'UserRow':
      return listData.map<UserRow>((data) => UserRow(data)).toList() as List<T>;
    case 'GroupRow':
      return listData.map<GroupRow>((data) => GroupRow(data)).toList()
          as List<T>;
    case 'AlbumRow':
      return listData.map<AlbumRow>((data) => AlbumRow(data)).toList()
          as List<T>;
    case 'AlbumCompositeRow':
      return listData
          .map<AlbumCompositeRow>((data) => AlbumCompositeRow(data))
          .toList() as List<T>;
    case 'PhotoRow':
      return listData.map<PhotoRow>((data) => PhotoRow(data)).toList()
          as List<T>;
    case 'PhotoCompositeRow':
      return listData
          .map<PhotoCompositeRow>((data) => PhotoCompositeRow(data))
          .toList() as List<T>;
    case 'MediaCompositeRow':
      return listData
          .map<MediaCompositeRow>((data) => MediaCompositeRow(data))
          .toList() as List<T>;
    default:
      throw 'list response missing implementation';
  }
}

class ApiStreamResponse<T> {
  final Future<ApiResponse<T>> done;
  final BehaviorSubject<double> progress =
      BehaviorSubject<double>().startWith(0);

  ApiStreamResponse(this.done);
}

class ApiBase {
  static String cookie = '';

  static String _baseUrl = 'http://svenbuskovromme.com/api';
  static String getRoute(String endpoint, {bool upload = false}) {
    String base = _baseUrl;
    if (upload) base += '/upload';

    return '$base/$endpoint';
  }

  static ApiStreamResponse<T> uploadStream<T>(
      String route, Stream<List<int>> stream, int length) {
    Uri uri = Uri.tryParse(getRoute(route, upload: true));

    var completer = Completer<ApiResponse<T>>();
    var streamResponse = ApiStreamResponse(completer.future);

    var client = HttpClient();
    client.putUrl(uri).then((request) async {
      request.headers.set('content-type', 'application/octet-stream');
      request.headers.set('cookie', cookie);

      int byteCount = 0;

      Stream<List<int>> stream2 = stream.transform(
        new StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            byteCount += data.length;
            streamResponse.progress.add(byteCount / length);
            sink.add(data);
          },
          handleError: (error, stack, sink) {},
          handleDone: (sink) {
            sink.close();
          },
        ),
      );

      await request.addStream(stream2);
      completer.complete(handleResponseIO(await request.close()));
    });

    return streamResponse;
  }

  static Future<ApiResponse<T>> put<T>(
      String route, Map<String, dynamic> body) async {
    Uri uri = Uri.tryParse(getRoute(route));

    var request = http.Request('put', uri);
    request.body = jsonEncode(body);
    request.headers['Content-Type'] = 'application/json';
    request.headers['cookie'] = cookie;

    var response = await http.Response.fromStream(await request.send());

    return handleResponse(response);
  }

  static Future<ApiResponse<T>> post<T>(
      String route, Map<String, dynamic> body) async {
    Uri uri = Uri.tryParse(getRoute(route));

    var request = http.Request('post', uri);
    request.body = jsonEncode(body);
    request.headers['Content-Type'] = 'application/json';
    request.headers['cookie'] = cookie;

    var response = await http.Response.fromStream(await request.send());

    return handleResponse(response);
  }

  static Future<ApiResponse<T>> get<T>(String route,
      {void Function(HttpClientRequest request) onRequest}) async {
    Uri uri = Uri.tryParse(getRoute(route));

    var client = HttpClient();
    var request = await client.getUrl(uri);
    request.headers.set('content-type', 'application/json');
    request.headers.set('cookie', cookie);

    if (onRequest != null) onRequest(request);

    var response = await request.close();

    return handleResponseIO(response);
  }

  static Future<ApiResponse<T>> patch<T>(
      String route, Map<String, dynamic> body) async {
    Uri uri = Uri.tryParse(getRoute(route));

    var client = HttpClient();
    var request = await client.patchUrl(uri);
    request.headers.set('content-type', 'application/json');
    request.headers.set('cookie', cookie);
    request.add(jsonEncode(body).codeUnits);

    var response = await request.close();

    return handleResponseIO(response);
  }

  static Future<ApiResponse<T>> delete<T>(
      String route, Map<String, dynamic> body) async {
    Uri uri = Uri.tryParse(getRoute(route));

    var client = HttpClient();
    var request = await client.deleteUrl(uri);
    request.headers.set('content-type', 'application/json');
    request.headers.set('cookie', cookie);
    request.add(jsonEncode(body).codeUnits);

    var response = await request.close();

    return handleResponseIO(response);
  }

  static Future<ApiResponse<T>> handleResponseIO<T>(
      HttpClientResponse response) async {
    var apiResponse = ApiResponse<T>();

    apiResponse.success = response.statusCode == 200;

    var bodyBuffer = StringBuffer();
    var completer = Completer();
    response.transform(utf8.decoder).listen((chunk) {
      bodyBuffer.write(chunk);
    }, onDone: () => completer.complete());
    await completer.future;
    var body = bodyBuffer.toString();

    if (apiResponse.success) {
      var data = jsonDecode(body);

      apiResponse.data =
          data is List ? getClassList(T, data) : getClass(T, data);
    } else
      apiResponse.errorMessage = body;

    if (response.headers['set-cookie'] != null &&
        response.headers['set-cookie'].contains('=')) {
      cookie = response.headers['set-cookie'].join(";");
    }

    return apiResponse;
  }

  static Future<ApiResponse<T>> handleResponse<T>(
      http.Response response) async {
    var apiResponse = ApiResponse<T>();

    apiResponse.success = response.statusCode == 200;

    if (apiResponse.success) {
      var data = jsonDecode(response.body);
      apiResponse.data =
          data is List ? getClassList(T, data) : getClass(T, data);
    } else
      apiResponse.errorMessage = response.body;

    if (response.headers['set-cookie'] != null &&
        response.headers['set-cookie'].contains('=')) {
      cookie = response.headers['set-cookie'];
    }

    return apiResponse;
  }
}

class ApiPut {
  static Future<ApiResponse<PrimaryKeyResponse>> group({String name}) async {
    return await ApiBase.put<PrimaryKeyResponse>('group', {'name': name});
  }

  static Future<ApiResponse<PrimaryKeyResponse>> album(
      {String name, int groupId}) async {
    return await ApiBase.put<PrimaryKeyResponse>(
        'album', {'name': name, 'groupId': groupId});
  }

  static Future<ApiResponse<PrimaryKeyResponse>> post({int albumId}) async {
    return await ApiBase.put<PrimaryKeyResponse>('post', {'albumId': albumId});
  }

  static Future<ApiResponse<PrimaryKeyResponse>> photo(
      {List<int> postIds, String format, int size}) async {
    return await ApiBase.put<PrimaryKeyResponse>(
        'photo', {'postIds': postIds, 'format': format, 'size': size});
  }

  static Future<ApiResponse<PrimaryKeyResponse>> video(
      {List<int> postIds, String format, int size, int duration}) async {
    return await ApiBase.put<PrimaryKeyResponse>('video', {
      'postIds': postIds,
      'format': format,
      'size': size,
      'duration': duration
    });
  }
}

class ApiPatch {
  static Future<ApiResponse<BoolResponse>> album(AlbumRow row) async {
    return await ApiBase.patch('album', {'row': row.serialize()});
  }

  static Future<ApiResponse<BoolResponse>> user(UserRow row) async {
    return await ApiBase.patch('user', {'row': row.serialize()});
  }

  static Future<ApiResponse<BoolResponse>> group(GroupRow row) async {
    return await ApiBase.patch('group', {'row': row.serialize()});
  }
}

class ApiDelete {
  static Future<ApiResponse<BoolResponse>> media(
      int mediaId, MediaType mediaType, int postId) async {
    return await ApiBase.delete(
        'media/$mediaId', {'type': mediaType, 'postId': postId});
  }

  static Future<ApiResponse<BoolResponse>> photo(
      int photoId, int postId) async {
    return await ApiBase.delete('photo/$photoId', {'postId': postId});
  }
}

class ApiUpload {
  static ApiStreamResponse<PrimaryKeyResponse> photo(
      Stream<List<int>> stream, String format, int size, int id) {
    return ApiBase.uploadStream<PrimaryKeyResponse>(
        'photo?id=$id', stream, size);
  }

  static ApiStreamResponse<PrimaryKeyResponse> video(
      Stream<List<int>> stream, String format, int size, int id) {
    return ApiBase.uploadStream<PrimaryKeyResponse>(
        'video?id=$id', stream, size);
  }
}

class ApiPost {
  static Future<ApiResponse<LoginResponse>> login(
      {String token, String username, String password}) async {
    var response = await ApiBase.post<LoginResponse>('login',
        {'token': token ?? '', 'username': username, 'password': password});

    return response;
  }

  static Future<ApiResponse<LoginResponse>> register(
      {String username, String password}) async {
    return await ApiBase.post<LoginResponse>(
        'register', {'username': username, 'password': password});
  }

  static Future<ApiResponse<BoolResponse>> groupStatus(
      {@required UserGroupStatus status,
      @required int userId,
      @required int groupId}) async {
    return await ApiBase.post<BoolResponse>('groupStatus',
        {'status': status.index, 'groupId': groupId, 'userId': userId});
  }
}

enum UserGroupStatus { None, Requested, Accepted }

class ApiGet {
  static Future<ApiResponse<List<UserRow>>> user(
      int groupId, UserGroupStatus status) async {
    return await ApiBase.get<List<UserRow>>(
        'user?groupId=$groupId&status=${status.index}');
  }

  static Future<ApiResponse<List<GroupRow>>> group({String nameLike}) async {
    return await ApiBase.get<List<GroupRow>>('group?nameLike=${nameLike ?? ''}',
        onRequest: (request) {
      if (nameLike != null)
        locator<DataService>().searchGroupsRequest = request;
    });
  }

  static Future<ApiResponse<List<AlbumCompositeRow>>> album(int groupId) async {
    return await ApiBase.get<List<AlbumCompositeRow>>('album?groupId=$groupId');
  }

  static Future<ApiResponse<List<MediaCompositeRow>>> media(int albumId) async {
    return await ApiBase.get<List<MediaCompositeRow>>('media?albumId=$albumId');
  }

  static Future<ApiResponse<List<PhotoCompositeRow>>> photo(int albumId) async {
    return await ApiBase.get<List<PhotoCompositeRow>>('photo?albumId=$albumId');
  }

  static Future<ApiResponse<GroupRow>> groupInstance(int id) async {
    return await ApiBase.get<GroupRow>('group/$id');
  }

  static Future<ApiResponse<AlbumRow>> albumInstance(int id) async {
    return await ApiBase.get<AlbumRow>('album/$id');
  }
}

enum photoType { Orignal, View, Thumbnail }
enum videoType { Original, Thumbnail }

class ApiUrl {
  static String photo(int id, {photoType type}) {
    String query = '';
    if (type != null && type != photoType.Orignal)
      query += '?type=${type == photoType.View ? 'view' : 'thumb'}';

    return ApiBase.getRoute('photo/$id$query');
  }

  static String video(int id, {videoType type}) {
    String query = '';
    if (type != null && type != videoType.Original) query += '?type=thumb';

    return ApiBase.getRoute('video/$id$query');
  }
}
