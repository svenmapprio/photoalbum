import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photoalbum/pages/album-details.dart';
import 'package:photoalbum/pages/group-details.dart';
import 'package:photoalbum/pages/home.dart';
import 'package:photoalbum/pages/user-details.dart';
import 'package:photoalbum/pages/user-edit.dart';
import 'package:photoalbum/services/data_service.dart';
import 'package:photoalbum/services/dialog_service.dart';
import 'package:photoalbum/services/share_service.dart';
import 'package:photoalbum/services/state_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/streams.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:flutter/material.dart';

import 'locator.dart';
import 'managers/dialog_manager.dart';
import 'pages/group-list.dart';
import 'pages/login.dart';
import 'pages/start.dart';
import 'api.dart';

void main() async {
  setupLocator();

  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(MyApp(firstCamera));
}

class MyApp extends StatefulWidget {
  final CameraDescription camera;

  MyApp(this.camera);
  // This widget is the root of your application.
  State<StatefulWidget> createState() => MyAppState();
}

class GroupLandingPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'For at lave albums, skal du være i en gruppe (f.eks. venner eller familie) \n\nTryk på en af knapperne nedenfor for enten at lave en ny gruppe eller være med i en eksisterende',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              child: Text('Ny gruppe'),
              onPressed: locator<DataService>().addGroup,
            ),
            ElevatedButton(child: Text('Find gruppe'), onPressed: () {})
          ],
        )
      ],
    ));
  }
}

class MainStreamMap {
  final UserRow user;
  final GroupRow group;
  final AlbumRow album;
  final List<PhotoRow> photos;
  final bool tokenChecked;
  final int bottomNavIndex;
  final List<SharedMediaFile> media;
  final bool userEditActive;

  MainStreamMap(DataService dataService, StateService stateService,
      ShareService shareService)
      : user = dataService.userRow.value,
        group = dataService.groupRow.value,
        album = dataService.albumRow.value,
        photos = dataService.photos.value,
        tokenChecked = stateService.tokenChecked.value,
        bottomNavIndex = stateService.bottomNavIndex.value,
        media = shareService.media.value,
        userEditActive = stateService.userEditActive.value;
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    _dataService.userRow.listen(_listen);
    _dataService.groupRow.listen(_listen);
    _dataService.albumRow.listen(_listen);
    _dataService.photos.listen(_listen);
    _stateService.tokenChecked.listen(_listen);
    _stateService.bottomNavIndex.listen(_listen);
    _shareService.media.listen(_listen);
    _stateService.userEditActive.listen(_listen);

    _checkToken();
  }

  BehaviorSubject<MainStreamMap> _stream =
      BehaviorSubject<MainStreamMap>().startWith(null);
  void _listen(_) {
    _stream.add(MainStreamMap(_dataService, _stateService, _shareService));
  }

  _checkToken() async {
    var prefs = await SharedPreferences.getInstance();

    var loginToken = prefs.getString('token');
    if (loginToken?.contains(':') == true) {
      var loginReply = await ApiPost.login(token: loginToken);

      if (loginReply.errorMessage == null) {
        await handleOnLoggedIn(loginReply.data);
      } else
        prefs.setString('token', '');
    }

    _stateService.tokenChecked.add(true);
  }

  var _shareService = locator<ShareService>();
  var _dialogService = locator<DialogService>();
  var _stateService = locator<StateService>();

  void _handleFloatActionPressed() {
    if (_shareService.media.value != null)
      _dialogService.confirmShareFiles();
    else if (_stateService.groupTabActive)
      _dataService.addAlbum();
    else if (_stateService.userTabActive) _dataService.addGroup();
  }

  Widget _getFloatingActionButton(List<SharedMediaFile> media) {
    return Visibility(
      visible: media != null,
      child: FloatingActionButton.extended(
          onPressed: _dialogService.confirmShareFiles,
          label: Text(_dataService.album.id > 0
              ? 'Upload til dette album'
              : 'Vælg albums til upload')),
    );
  }

  FloatingActionButtonLocation _getFloatingActionLocation(
      List<SharedMediaFile> media) {
    return media != null
        ? FloatingActionButtonLocation.centerFloat
        : FloatingActionButtonLocation.endFloat;
  }

  Color _getBottomNavColor(
      BuildContext context, int targetIndex, int sourceIndex) {
    return targetIndex == sourceIndex
        ? Theme.of(context).primaryColorDark
        : Colors.black38;
  }

  @override
  Widget build(BuildContext context) {
    List<MaterialPage> pages(MainStreamMap data) {
      print(data?.tokenChecked);
      return <MaterialPage>[
        MaterialPage(
            child: DialogManager(child: Container(height: 0, width: 0))),
        if (data?.user == null || data.user.id <= 0)
          MaterialPage(child: LoginPage(onLoggedIn: handleOnLoggedIn)),
        if (data?.user != null && data.user.id > 0)
          MaterialPage(
              child: Scaffold(
            body: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: data?.bottomNavIndex == 0
                          ? GroupListPage()
                          : data?.bottomNavIndex == 1
                              ? data?.group != null && data.group.id > 0
                                  ? GroupDetailsPage()
                                  : GroupLandingPage()
                              : data?.bottomNavIndex == 2
                                  ? UserDetailsPage()
                                  : Container(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.view_list),
                          color: _getBottomNavColor(
                              context, data.bottomNavIndex, 0),
                          onPressed: () => _stateService.bottomNavIndex.add(0),
                        ),
                        IconButton(
                            icon: Icon(Icons.home),
                            color: _getBottomNavColor(
                                context, data.bottomNavIndex, 1),
                            onPressed: () =>
                                _stateService.bottomNavIndex.add(1)),
                        IconButton(
                            icon: Icon(Icons.person),
                            color: _getBottomNavColor(
                                context, data.bottomNavIndex, 2),
                            onPressed: () =>
                                _stateService.bottomNavIndex.add(2))
                      ],
                    )
                  ],
                ),
                Positioned(
                    child: _getFloatingActionButton(data?.media), bottom: 50.0)
              ],
            ),

            // floatingActionButton: _getFloatingActionButton(data?.media),
            // floatingActionButtonLocation:
            //     FloatingActionButtonLocation.centerFloat,
          )),
        // if (data?.group != null && data.group.id > 0)
        //   MaterialPage(child: GroupDetailsPage()),
        if (data?.album != null && data.album.id > 0)
          MaterialPage(child: AlbumDetailsPage()),
        if (data?.userEditActive == true) MaterialPage(child: UserEditPage()),

        if (data?.tokenChecked != true)
          MaterialPage(
              child: Container(
                  child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [CircularProgressIndicator()],
                  )),
                  color: Colors.grey)),
      ];
    }

    Widget builder(
        BuildContext context, AsyncSnapshot<MainStreamMap> snapshot) {
      return MaterialApp(
        title: 'Fotoalbum',
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Navigator(
          onPopPage: (route, result) {
            if (!route.didPop(result)) {
              return false;
            }

            if (snapshot.data != null) {
              if (snapshot.data.album.id > 0)
                _dataService.albumRow.add(null);
              // else if (snapshot.data.group.id > 0)
              //   _dataService.groupRow.add(null);
              else if (snapshot.data.user.id > 0) return false;
            }

            // if (snapshot.data.photos == null && snapshot.data.user.id > 0)
            //   return false;

            return true;
          },
          pages: pages(snapshot.data),
        ),
      );
    }

    return StreamBuilder(
      builder: builder,
      stream: _stream,
      // initialData: MainStreamMap(
      //     _dataService.userRow.value,
      //     _dataService.groupRow.value,
      //     _dataService.albumRow.value,
      //     _dataService.photos.value,
      //     _tokenChecked.value),
    );
  }

  DataService _dataService = locator<DataService>();

  Future<void> handleOnLoggedIn(LoginResponse loginResponse) async {
    _dataService.userRow.add(loginResponse.user);

    var prefs = await SharedPreferences.getInstance();
    prefs.setString('token', loginResponse.token);

    if (_dataService.user.id > 0) {
      _dataService.user.setFromRow(loginResponse.user);
      var groupRes = await ApiGet.group();

      if (groupRes.data != null) _dataService.groups.add(groupRes.data);
    }

    // setState(() {});
  }

  handleOnLoggedOut() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('token', '');
    // setState(() {
    //   _dataService.user.id = 0;
    // });
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            await _controller.takePicture(path);

            // Attempt to take a picture and log where it's been saved.

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
