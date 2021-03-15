import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final StreamController _dividerController = StreamController<int>();
  int selected = 0;
  @override
  void dispose() {
    _dividerController.close();
    super.dispose();
  }

  press() {
    setState(() {
      selected = Random().nextInt(8);
    });
  }

  List colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.pink,
    Colors.orange,
    Colors.yellowAccent.shade400,
    Colors.purple,
    Colors.teal.shade100
  ];
  bool display = false;
  @override
  Widget build(BuildContext context) {
    final items = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
    ];
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            selected = Random().nextInt(items.length);
          });
        },
        child: Column(
          children: <Widget>[
            Expanded(
              child: FortuneWheel(
                animateFirst: false,
                onAnimationEnd: () { setState(() {
                  display = true;
                });},
                onAnimationStart: () {  setState(() {
                  display = false;
                });},
                selected: selected,
                items: [
                  for (var it in items)
                    FortuneItem(
                        style: FortuneItemStyle(
                          color: colors[int.parse(it) -
                              1], // <-- custom circle slice fill color
                          borderColor: colors[int.parse(it) -
                              1], // <-- custom circle slice stroke color
                          borderWidth:
                              3, // <-- custom circle slice stroke width
                        ),
                        child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              it,
                              style: TextStyle(color: Colors.black),
                            ))),
                ],
              ),
            ),
            ButtonBar(
              children: <Widget>[
                TextButton(
                  child: Text('Spin',style: TextStyle(color: Colors.white),),
                  style: TextButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    this.press();
                  },
                ),
              ],
            ),
            Text(display ? items[selected] : '')
          ],
        ),
      ),
    );
  }

  double _generateRandomAngle() => Random().nextDouble() * pi * 2;
}
