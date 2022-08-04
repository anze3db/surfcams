import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'video_view.dart';

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

Color parseColor(String color) =>
    Color(int.parse('FF${color.replaceAll("#", '')}', radix: 16));

class Category {
  final String title;
  final Color color;
  final List<Cam> cams;

  const Category(
      {required this.title, required this.color, required this.cams});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        title: json['title'] as String,
        cams: (json['cams'] as List)
            .map((c) => Cam(
                title: c['title'] as String,
                url: c['url'] as String,
                subTitle: c['subTitle'] as String,
                titleColor: parseColor(c['titleColor'] as String),
                subTitleColor: parseColor(c['subTitleColor'] as String),
                backgroundColor: parseColor(c['backgroundColor'] as String)))
            .toList(),
        color: Color(
            int.parse('FF${json['color'].replaceAll("#", '')}', radix: 16)));
  }
}

class Cam {
  final String title;
  final String subTitle;
  final String url;
  final Color titleColor;
  final Color subTitleColor;
  final Color backgroundColor;

  const Cam(
      {required this.title,
      required this.subTitle,
      required this.url,
      required this.titleColor,
      required this.subTitleColor,
      required this.backgroundColor});
}

const camsUrl = 'https://surfcams.pecar.me/api/cams.json';
Future<List<Category>> fetchCams() async {
  String bodyStr;
  final prefs = await SharedPreferences.getInstance();

  try {
    final response = await http.get(Uri.parse(camsUrl));
    if (response.statusCode != 200) {
      throw Exception('Status code was not 200');
    }
    log('Fetched cams from server');
    bodyStr = utf8.decode(response.bodyBytes);
    await prefs.setString('cams', bodyStr);
  } catch (e) {
    log(e.toString());
    final cached = prefs.getString('cams');
    if (cached != null) {
      bodyStr = cached;
      log('Fetched cams from cache');
    } else {
      throw Exception('Failed to load cams');
    }
  }

  final results = jsonDecode(bodyStr)['categories'] as List;

  return results.map((c) => Category.fromJson(c)).toList();
}

class SurfCams extends StatefulWidget {
  const SurfCams({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SurfCamsState createState() => _SurfCamsState();
}

class _SurfCamsState extends State<SurfCams> {
  late Future<List<Category>> fetchCamsFuture;

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
          CupertinoSliverRefreshControl(
            onRefresh: () async => setState(() {
              log("Fetching after scroll up");
              fetchCamsFuture = fetchCams();
            }),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
                color: CupertinoColors.black,
                child: Column(children: <Widget>[
                  FutureBuilder<List<Category>>(
                    future: fetchCamsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return CamsListView(categories: snapshot.data!);
                      } else if (snapshot.hasError) {
                        return Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text('${snapshot.error}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                    fontSize: 14)));
                      }
                      // By default, show a loading spinner.
                      return const Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: CupertinoActivityIndicator(radius: 20));
                    },
                  ),
                  const SizedBox(height: 40),
                ])),
          )
        ]));
  }
}

class CamsListView extends StatelessWidget {
  final List<Category> categories;
  const CamsListView({Key? key, required this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
          padding: EdgeInsets.only(top: 100), child: Text('No cams found'));
    }
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
                        child: Text(category.title,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: category.color,
                                fontSize: 14))),
                    SizedBox(
                        height: 70,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: category.cams.length,
                            itemBuilder: (context, index) => CamItemView(
                                cam: category.cams.elementAt(index)))),
                  ]));
        }).toList());
  }
}

class CamItemView extends StatelessWidget {
  final Cam cam;
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
                color: cam.backgroundColor,
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
                      Text(cam.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cam.titleColor,
                          )),
                      Text(cam.subTitle,
                          style:
                              TextStyle(fontSize: 10, color: cam.subTitleColor))
                    ]))));
  }
}
