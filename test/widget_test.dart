// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_gen_app/main.dart';

void main() {
  testWidgets('Displays welcome copy', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteGenApp());

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Avoid Zone'), findsOneWidget);
    expect(find.text('Route Zone'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('actions-toolbar')), findsOneWidget);
    expect(find.byKey(const ValueKey('layer-menu-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('undo-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('redo-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('clear-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('download-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-search-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode-toggle-button')), findsOneWidget);
  });
}
