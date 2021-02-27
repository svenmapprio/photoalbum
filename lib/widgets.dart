import 'package:flutter/material.dart';
import 'package:photoalbum/services/state_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:async/async.dart';
import 'package:video_player/video_player.dart';
import 'package:better_player/better_player.dart';

import 'api.dart';

import 'locator.dart';

class DrawerAppBar extends AppBar {
  DrawerAppBar({Widget title})
      : super(
            title: title,
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                locator<StateService>()
                    .startPageScaffold
                    .currentState
                    .openDrawer();
              },
            ));
}

class RowStreamName<T extends TableInstanceRow> extends StreamBuilder {
  RowStreamName(BehaviorSubject<T> subject)
      : super(
            stream: subject.stream,
            builder: (context, snapshot) {
              return Text(snapshot.hasData ? snapshot.data.name : '');
            });
}

class StreamText extends StreamBuilder {
  StreamText(BehaviorSubject<String> subject)
      : super(
            stream: subject.stream,
            builder: (context, snapshot) {
              return Text(snapshot.hasData ? snapshot.data : '');
            });
}

class Thumbnail extends StatelessWidget {
  final int mediaId;
  final double height;
  final MediaType type;

  Thumbnail({this.height = 50.0, @required this.mediaId, @required this.type});
  Thumbnail.fromPreview(AlbumPreview preview, {this.height = 50.0})
      : mediaId = preview.photoId ?? preview.videoId,
        type = preview.photoId != null
            ? MediaType.Photo
            : preview.videoId != null
                ? MediaType.Video
                : throw 'mediatype not valid';

  @override
  Widget build(BuildContext context) {
    return Image.network(
      this.type == MediaType.Photo
          ? ApiUrl.photo(mediaId, type: photoType.Thumbnail)
          : ApiUrl.video(mediaId, type: videoType.Thumbnail),
      headers: {'cookie': ApiBase.cookie},
      height: height,
    );
  }
}

class PhotoView extends StatelessWidget {
  final int photoId;

  PhotoView({@required this.photoId});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      ApiUrl.photo(photoId, type: photoType.View),
      headers: {'cookie': ApiBase.cookie},
    );
  }
}

class VideoView extends StatelessWidget {
  final int videoId;

  VideoView({@required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300, height: 300, child: VideoPlayerScreen(videoId));
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final int videoId;
  VideoPlayerScreen(this.videoId, {Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  BetterPlayerController _controller;
  // Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.

    _controller = BetterPlayerController(BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource.network(
            ApiUrl.video(widget.videoId),
            headers: {'cookie': ApiBase.cookie}));
    // _controller = VideoPlayerController.network(ApiUrl.video(widget.videoId));

    // Initialize the controller and store the Future for later use.
    // _initializeVideoPlayerFuture = _controller;

    // Use the controller to loop the video.
    _controller.setLooping(true);

    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Butterfly Video'),
      ),
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      body: BetterPlayer(
        controller: _controller,
      ),
      // body: FutureBuilder(
      //   future: _initializeVideoPlayerFuture,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.done) {
      //       // If the VideoPlayerController has finished initialization, use
      //       // the data it provides to limit the aspect ratio of the video.
      //       return AspectRatio(
      //         aspectRatio: _controller.value.aspectRatio,
      //         // Use the VideoPlayer widget to display the video.
      //         child: VideoPlayer(_controller),
      //       );
      //     } else {
      //       // If the VideoPlayerController is still initializing, show a
      //       // loading spinner.
      //       return Center(child: CircularProgressIndicator());
      //     }
      //   },
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Wrap the play or pause in a call to `setState`. This ensures the
          // correct icon is shown.
          setState(() {
            // If the video is playing, pause it.
            if (_controller.isPlaying()) {
              _controller.pause();
            } else {
              // If the video is paused, play it.
              _controller.play();
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _controller.isPlaying() ? Icons.pause : Icons.play_arrow,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class InlineButton extends StatelessWidget {
  final Function _onPressed;
  final String text;
  final IconData icon;

  InlineButton(this._onPressed, {this.text = 'Tilføj', this.icon = Icons.add});

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
          )
        ],
      ),
      onPressed: _onPressed,
    );
  }
}
