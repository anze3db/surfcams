import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:wakelock/wakelock.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoViewPage extends StatelessWidget {
  final String url;
  final String detailUrl;
  const VideoViewPage({Key? key, required this.url, required this.detailUrl})
      : super(key: key);

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
            color: CupertinoColors.black,
            child: ListView(children: [
              VideoView(url: url),
              DetailView(url: detailUrl),
            ])));
  }
}

class DetailView extends StatefulWidget {
  final String url;

  const DetailView({super.key, required this.url});

  @override
  // ignore: library_private_types_in_public_api
  _DetailViewState createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: WebViewWidget(controller: _controller));
  }

  @override
  void dispose() {
    super.dispose();
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
      return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 100,
          child: const CupertinoActivityIndicator(
              color: CupertinoColors.white, radius: 20));
    }

    return OrientationBuilder(builder: (context, orientation) {
      var isPortrait = orientation == Orientation.portrait;
      return SizedBox(
          width: MediaQuery.of(context).size.width,
          height:
              MediaQuery.of(context).size.width / _controller.value.aspectRatio,
          child: Center(
              child: Stack(
            //This will help to expand video in Horizontal mode till last pixel of screen
            fit: isPortrait ? StackFit.loose : StackFit.expand,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ],
          )));
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
