// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surfcams/main.dart';

void main() {
  testWidgets('Empty SurfcamListView', (WidgetTester tester) async {
    await tester
        .pumpWidget(const CupertinoApp(home: CamsListView(categories: [])));

    expect(find.text('No cams found'), findsOneWidget);
  });
  testWidgets('SurfcamListView with single', (WidgetTester tester) async {
    const cat1 = Category(
        title: "My Category", color: CupertinoColors.activeBlue, cams: []);

    await tester
        .pumpWidget(const CupertinoApp(home: CamsListView(categories: [cat1])));

    expect(find.text('No cams found'), findsNothing);
    expect(find.text('My Category'), findsOneWidget);
  });
}
