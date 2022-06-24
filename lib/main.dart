import 'dart:convert';
import 'dart:developer';

import 'package:video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MainWidget());

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromWindow(
        child: const CupertinoApp(
            useInheritedMediaQuery: true,
            title: 'Surfcams',
            home: CupertinoPageScaffold(child: SurfCams())));
  }
}

class Cams {
  final String name;
  final String category;
  final String url;
  final String source;
  final Color color;

  const Cams(
      {required this.name,
      required this.category,
      required this.url,
      required this.source,
      required this.color});

  factory Cams.fromJson(Map<String, dynamic> json) {
    return Cams(
        name: json['name'] as String,
        category: json['category'] as String,
        url: json['url'] as String,
        source: json['source'] as String,
        color: Color(
            int.parse('FF${json['color'].replaceAll("#", '')}', radix: 16)));
  }
}

const camsUrl = 'https://surfcams.pecar.me/api/cams.json';
Future<List<Cams>> fetchCams() async {
  final response = await http.get(Uri.parse(camsUrl));
  if (response.statusCode == 200) {
    final results = jsonDecode(utf8.decode(response.bodyBytes))['cams'] as List;
    return results.map((c) => Cams.fromJson(c)).toList();
  } else {
    throw Exception('Failed to load');
  }
}

class SurfCams extends StatefulWidget {
  const SurfCams({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SurfCamsState createState() => _SurfCamsState();
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  LifecycleEventHandler({required this.resumeCallBack});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    log("App lifecyle");
    if (state != AppLifecycleState.resumed) {
      return;
    }
    log("App lifecyle resumed");
    await resumeCallBack();
  }
}

class _SurfCamsState extends State<SurfCams> {
  late Future<List<Cams>> fetchCamsFuture;

  @override
  void initState() {
    super.initState();
    fetchCamsFuture = fetchCams();
    WidgetsBinding.instance.addObserver(LifecycleEventHandler(
        resumeCallBack: () async => setState(() {
              log("Fetching after resume");
              fetchCamsFuture = fetchCams();
            })));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: CupertinoColors.black,
        child: CustomScrollView(slivers: <Widget>[
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Surfcams',
                style: TextStyle(color: CupertinoColors.white)),
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.black,
                width: 1,
              ),
            ),
            backgroundColor: CupertinoColors.black,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
                color: CupertinoColors.black,
                child: Column(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FutureBuilder<List<Cams>>(
                        future: fetchCamsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return CamsListView(cams: snapshot.data!);
                          } else if (snapshot.hasError) {
                            return Text('${snapshot.error}');
                          }
                          // By default, show a loading spinner.
                          return const CupertinoActivityIndicator();
                        },
                      ),
                      const SizedBox(height: 40),
                    ])),
          )
        ]));
  }
}

class CamsListView extends StatelessWidget {
  final List<Cams> cams;
  const CamsListView({Key? key, required this.cams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = cams.map((c) => c.category).toSet().toList();
    final categoriesMap = {
      for (var category in categories)
        category: cams.where((cam) => cam.category == category)
    };
    final categoryColors = {
      for (var category in categories)
        category: cams.where((cam) => cam.category == category).first.color
    };

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((category) {
          return Container(
              decoration: const BoxDecoration(
                  color: CupertinoColors.darkBackgroundGray,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              margin: const EdgeInsets.only(top: 6.0, left: 10.0, right: 10.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding:
                            const EdgeInsets.only(left: 8.0, bottom: 8, top: 8),
                        child: Text(category,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: categoryColors[category],
                                fontSize: 14))),
                    SizedBox(
                        height: 70,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categoriesMap[category]!.length,
                            itemBuilder: (context, index) => CamItemView(
                                cam: categoriesMap[category]!
                                    .elementAt(index)))),
                  ]));
        }).toList());
  }
}

class CamItemView extends StatelessWidget {
  final Cams cam;
  const CamItemView({Key? key, required this.cam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        margin:
            const EdgeInsets.only(top: 0.0, left: 6.0, right: 0.0, bottom: 6),
        child: SizedBox(
            width: 90,
            child: CupertinoButton(
                color: const Color.fromARGB(255, 54, 53, 53),
                onPressed: () {
                  log("Cam view pressed");
                  Navigator.push(context, CupertinoPageRoute<Widget>(
                      builder: (BuildContext context) {
                    return VideoViewPage(url: cam.url);
                  }));
                },
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(cam.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(cam.source,
                          style: const TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.inactiveGray))
                    ]))));
  }
}

class VideoViewPage extends StatelessWidget {
  final String url;
  const VideoViewPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context);
        },
        onDoubleTap: () {
          Navigator.pop(context);
        },
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
  }
}
