import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ad_state.dart';
import 'package:firebase_core/firebase_core.dart';

var url = 'api.keng.com.vn';

String bannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-8585499129481868/5093586990';

var client = http.Client();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);
  var res = await client
      .post(Uri.http(url, '/api/mobile/mobile.asmx/portalGet'),body : {'mID' : '9'});
  if (res.statusCode == 200) {
      bannerAdUnitId = Platform.isAndroid
          ? json.decode(res.body)['data']['a_BieuNgu']
          : json.decode(res.body)['data']['i_BieuNgu'];
  }
  await Firebase.initializeApp();
  runApp(Provider.value(
    value: adState,
    builder: (context, child) => MyApp(),
  ));
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
  BannerAd banner;
  final StreamController _dividerController = StreamController<int>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  int selected = 0;
  var appID = '';
  @override
  void initState() {
    getFromAPI();
    super.initState();
    firebaseCloudMessaging_Listeners();
  }

  void getFromAPI() async {

    var postUrl = '/api/mobile/mobile.asmx/appAdd';
    var response = await client.post(Uri.http(url, postUrl), body: {
      'mID': '9',
      'appID': "",
      'appSystem': Platform.isAndroid ? '0' : '1'
    });
    if (response.statusCode == 200) {
      setState(() {
        appID = json.decode(response.body)['data'];
      });
    }
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);
    adState.initialization.then((status) {
      setState(() {
        banner = BannerAd(
          adUnitId: bannerAdUnitId,
          size: AdSize.banner,
          request: AdRequest(),
          listener: adState.adListener,
        )..load();
      });
    });
  }

  @override
  void dispose() {
    _dividerController.close();
    super.dispose();
  }

  void firebaseCloudMessaging_Listeners() {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token) async {
      var client = http.Client();
      var postUrl = '/api/mobile/mobile.asmx/fcmAdd';
      var response = await client.post(Uri.http(url, postUrl), body: {
        'mID': '9',
        'appID': appID,
        'token': token,
        'appSystem': Platform.isAndroid ? '0' : '1'
      });
      print('token : ${response.statusCode}');
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  press() {
    setState(() {
      selected = Random().nextInt(8);
      display = false;
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
    final itemss = <String>[
      'Đồng khởi',
      'Tự sướng một chén',
      'Uống chỉ định với bất kỳ ai',
      'Uống một chén với người ngồi bên phải',
      'Qua lượt vượt ải thành công',
      'Tự sướng nửa chén',
      'Tự sướng nửa chén và thêm một lượt quay',
      'Uống một chén với người ngồi bên trái',
    ];
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            selected = Random().nextInt(items.length);
          });
        },
        child: Column(
          children: [
            Expanded(
              child: FortuneWheel(
                animateFirst: false,
                onAnimationEnd: () {
                  setState(() {
                    display = true;
                  });
                },
                onAnimationStart: () {
                  setState(() {
                    display = false;
                  });
                },
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
                            child: Container(
                                margin: EdgeInsets.fromLTRB( 0, 0,  0, 50),
                                width: 80,
                                alignment: Alignment.center,
                                child: Text(itemss[int.parse(it) - 1],
                                    style: TextStyle(
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center)))),
                ],
              ),
            ),
            Text(
              display ? itemss[selected] : '',
              style: TextStyle(
                fontSize: 30,
                foreground: Paint()
                  ..shader = ui.Gradient.linear(
                    const Offset(0, 20),
                    const Offset(150, 0),
                    <Color>[
                      Colors.black,
                      Colors.red,
                    ],
                  ),
              ),
            ),
            ButtonBar(
              children: <Widget>[
                TextButton(
                  child: Text(
                    'Spin',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    this.press();
                  },
                ),
              ],
            ),
            if (banner == null)
              SizedBox(height: 50)
            else
              Container(
                height: 50,
                child: AdWidget(ad: banner),
              )
          ],
        ),
      ),
    );
  }

}
