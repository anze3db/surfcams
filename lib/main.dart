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
            title: 'Surf Cams',
            home: CupertinoPageScaffold(child: SurfCams())));
  }
}

class Cams {
  final String name;
  final String category;
  final String url;
  final String source;

  const Cams({
    required this.name,
    required this.category,
    required this.url,
    required this.source,
  });

  factory Cams.fromJson(Map<String, dynamic> json) {
    return Cams(
      name: json['name'] as String,
      category: json['category'] as String,
      url: json['url'] as String,
      source: json['source'] as String,
    );
  }
}

const camsUrl = 'https://surfcams.pecar.me/api/cams.json';
Future<List<Cams>> fetchCams() async {
  final response = await http.get(Uri.parse(camsUrl));
  if (response.statusCode == 200) {
    final results = jsonDecode(response.body)['cams'] as List;
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
    return CustomScrollView(slivers: <Widget>[
      const CupertinoSliverNavigationBar(
        largeTitle: Text('Surf Cams'),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.extraLightBackgroundGray,
            width: 1,
          ),
        ),
        backgroundColor: CupertinoDynamicColor.withBrightness(
            color: CupertinoColors.extraLightBackgroundGray,
            darkColor: CupertinoColors.darkBackgroundGray),
      ),
      SliverFillRemaining(
        child: Container(
            color: const CupertinoDynamicColor.withBrightness(
                color: CupertinoColors.extraLightBackgroundGray,
                darkColor: CupertinoColors.darkBackgroundGray),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // const SizedBox(height: 120),
                ])),
      )
    ]);
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

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((category) {
          return Container(
              decoration: const BoxDecoration(
                  color: CupertinoDynamicColor.withBrightness(
                    color: CupertinoColors.white,
                    darkColor: CupertinoColors.darkBackgroundGray,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              margin: const EdgeInsets.only(top: 18.0, left: 18.0, right: 18.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, bottom: 16, top: 16),
                        child: Text(
                          category,
                          textAlign: TextAlign.left,
                        )),
                    SizedBox(
                        height: 200,
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
            const EdgeInsets.only(top: 0.0, left: 14.0, right: 0.0, bottom: 14),
        child: CupertinoButton.filled(
            onPressed: () {
              log("Cam view pressed");
              Navigator.push(context,
                  CupertinoPageRoute<Widget>(builder: (BuildContext context) {
                return VideoViewPage(url: cam.url);
              }));
            },
            child: Text('${cam.name} ${cam.source}')));
  }
}

class VideoViewPage extends StatelessWidget {
  final String url;
  const VideoViewPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VideoView(url: url);
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          if (!_controller.value.isPlaying) {
            _controller.play();
          }
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Container();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
