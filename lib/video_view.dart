import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:wakelock/wakelock.dart';

class VideoViewPage extends StatelessWidget {
  final String url;
  const VideoViewPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void close() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      Navigator.pop(context);
    }

    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: close,
        onDoubleTap: close,
        child: Container(
            color: CupertinoColors.black, child: VideoView(url: url)));
  }
}

class VideoView extends StatefulWidget {
  final String url;

  const VideoView({super.key, required this.url});

  @override
  // ignore: library_private_types_in_public_api
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();

    Wakelock.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          log('${_controller.value.isPlaying}, ${_controller.value.isBuffering}, ${_controller.value.isInitialized}');
          if (!_controller.value.isPlaying) {
            _controller.play();
          }
        });
      }, onError: (error) {
        setState(() {
          _isError = true;
        });
        log('Error: $error');
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
          child: Text('Error Loading Cam',
              textAlign: TextAlign.center,
              style: TextStyle(color: CupertinoColors.white)));
    }
    if (!_controller.value.isPlaying) {
      return const CupertinoActivityIndicator(
          color: CupertinoColors.white, radius: 20);
    }
    return OrientationBuilder(builder: (context, orientation) {
      var isPortrait = orientation == Orientation.portrait;
      return Center(
          child: Stack(
        //This will help to expand video in Horizontal mode till last pixel of screen
        fit: isPortrait ? StackFit.loose : StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ],
      ));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    Wakelock.disable();
    log('dispose called');
  }
}
