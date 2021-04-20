// @dart=2.9
import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ad_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'local_storage.dart';
import 'package:open_appstore/open_appstore.dart';
import 'screen.dart';
import 'package:flutter/services.dart' ;
import 'package:flutter/gestures.dart';


var url = 'api.keng.com.vn';
final _storage = new LocalStorage();

String bannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-8585499129481868/5093586990';
var client = http.Client();
var version = Platform.isAndroid ? '1.2' : '1.3';
bool isVersion = true;
var linkup = '';
Future<bool> check() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

void main() async {
  GestureBinding.instance?.resamplingEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);
  check().then((intenet) async {
    if (intenet != null && intenet) {

      var res = await client.post(
          Uri.http(url, '/api/mobile/mobile.asmx/portalGet'),
          body: {'mID': '9'});
      if (res.statusCode == 200) {
        bannerAdUnitId = Platform.isAndroid
            ? json.decode(res.body)['data']['a_BieuNgu']
            : json.decode(res.body)['data']['i_BieuNgu'];
        var dataVs = Platform.isAndroid
            ? json.decode(res.body)['data']['a_Version']
            : json.decode(res.body)['data']['i_Version'];
        linkup = Platform.isAndroid ? json.decode(res.body)['data']['a_LinkUp'] : json.decode(res.body)['data']['i_LinkUp'];
        if (version != dataVs) {
          isVersion = false;
        }
      }
      await Firebase.initializeApp();
      runApp(Provider.value(
        value: adState,
        builder: (context, child) => MyApp(),
      ));
    } else {
      runApp(Provider.value(
        value: adState,
        builder: (context, child) => MyApp(),
      ));
    }
    // No-Internet Case
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return  FutureBuilder(
      // Replace the 3 second delay with your initialization code:
        future: Future.delayed(Duration(seconds: 3)),
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
            return  MaterialApp(home: Splash());
          } else {
            // Loading is done, return the app:
              if (isVersion) {
                return MaterialApp(home: MyHomePage());
              } else {
                return MaterialApp(home: MyDialog());
              }
          }
          },
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
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  AudioCache audioCache = AudioCache();
  AudioPlayer advancedPlayer = AudioPlayer();
  int selected = Random().nextInt(8);
  var appID = '';
  bool playMusic = true;

  @override
  void initState() {
    Screen.keepOn(true);
    check().then((intenet) async {
      if (intenet != null && intenet) {
        getFromAPI();
        super.initState();
        if (Platform.isIOS) {
          if (audioCache.fixedPlayer != null) {
            audioCache.fixedPlayer.startHeadlessService();
          }
        }
        firebaseCloudMessaging_Listeners();
      }
      // No-Internet Case
    });
  }

  var value;
  void getFromAPI() async {
    var _background = await _storage.readValue('backgroundMusic');
    value = await _storage.readValue('isFirstTime');

        if (value == null) {
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

    if (_background == null) {
      setState(() {
        playMusic = true;
      });
      _storage.writeValue('backgroundMusic', this.playMusic.toString());
    } else {
      setState(() {
        _background == "true" ? playMusic = true : playMusic = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);
    check().then((intenet) async {
      if (intenet != null && intenet) {
        adState.initialization.then((status) {
          setState(() {
            banner = BannerAd(
              adUnitId: bannerAdUnitId,
              size: AdSize.banner,
              request: AdRequest(),
              listener: adState.adListener,
            )
              ..load();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _dividerController.close();
    super.dispose();
  }

  void firebaseCloudMessaging_Listeners() {
    check().then((intenet) async {
      if (intenet != null && intenet) {
        if (Platform.isIOS) iOS_Permission();
        if (value == null) {
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
          _storage.writeValue('isFirstTime', '1');
        }
      }
    });

  }

  bool display = false;
  bool isFirstTime = true;

  void iOS_Permission() {
    _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,);

  }
  var checkValue = 8;

  AudioPlayer player = new AudioPlayer();
  press() async {
    selected = Random().nextInt(8);
    while(selected == checkValue) {
      selected = Random().nextInt(8);
    }

    setState(() {
      checkValue = selected;
      selected = selected;
      display = false;
      isFirstTime = false;
    });
    if (playMusic) {
      player = await audioCache.play('backgroundMusic.mp3');
    } else {
      audioCache.clearCache();
    }

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
      'Qua lượt',
      'Uống bên trái',
      'Uống nửa ly',
      'Uống hai ly',
      'Chỉ định',
      'Uống bên phải',
      'Uống cạn ly',
      'Đồng khởi',
    ];

    return DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("bg-beer.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(0, 30, 0, 0),
                  child: ButtonBar(
                    children: <Widget>[
                      !playMusic
                          ? TextButton(
                              child: Icon(
                                Icons.volume_off,
                                size: 25,
                              ),
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent),
                              onPressed: () {
                                setState(() {
                                  playMusic = true;
                                });
                                _storage.deleteValue('backgroundMusic');
                                _storage.writeValue('backgroundMusic', "true");
                              })
                          : TextButton(
                              child: Icon(
                                Icons.volume_up,
                                size: 25,
                              ),
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent),
                              onPressed: () {
                                setState(() {
                                  playMusic = false;
                                });
                                player.stop();
                                _storage.deleteValue('backgroundMusic');
                                _storage.writeValue('backgroundMusic', "false");
                              }),
                    ],
                  ),
                ),
                Container(
                  height: 60,
                  child: Text(
                    display ? itemss[selected] : '1  2  3  dzô!!!',
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
                ),
                Expanded(
                    child: RotatedBox(
                  quarterTurns: 2,
                  child: FortuneWheel(
                    animateFirst: false,
                    onAnimationEnd: () {
                      audioCache.clearCache();
                      setState(() {
                        display = true;
                        isFirstTime = true;
                      });
                    },
                    onAnimationStart: () {
                      setState(() {
                        display = false;
                      });
                    },
                    duration: Duration(seconds: 15),
                    selected: selected,
                    physics: NoPanPhysics(),
                    items: [
                      for (var it in items)
                        FortuneItem(
                            style: FortuneItemStyle(
                              color: Colors
                                  .transparent, // <-- custom circle slice fill color
                              borderColor: Colors.transparent, //
                              textAlign: TextAlign.center,
                              // <-- custom circle slice stroke width
                            ),
                            child: Transform.translate(
                                offset: const Offset(-3.0, 0.0),
                                child: RotatedBox(
                                    quarterTurns: 1,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage("$it.png"),
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                        child: Container()))))
                    ],
                  ),
                )),
                Container(
                    alignment: Alignment.center,
                    height: 170,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: isFirstTime ?
                        TextButton(
                        child: new Image.asset(
                          'Buttton-QuayTiep.png',
                          width: 150,
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        ),
                        onPressed: () {
                           this.press();
                        },
                      ): Container(),
                    )),
                if (banner == null)
                  SizedBox(height: 50)
                else
                  Container(
                    height: 50,
                    child: AdWidget(ad: banner),
                  ),
              ],
            ),
          ),
        ));
  }
}



class MyDialog extends StatefulWidget {
  @override
  _MyDialogState createState() => new _MyDialogState();
}

class _MyDialogState extends State<MyDialog> {
  bool backgroundMusic = true;
  bool talkMusic = true;
  var value = null;
  @override
  void initState() {
    super.initState();
  }

  save() async {
    _storage.writeValue('backgroundMusic', this.backgroundMusic.toString());
    _storage.writeValue('talkMusic', this.talkMusic.toString());
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text('Thông báo'),
        content: Text(
            'Đã có phiên bản cập nhật mới. Vui lòng cập nhật trước khi tiếp tục!'),
        actions: [
          TextButton(
              onPressed: () {
                OpenAppstore.launch(
                    androidAppId: linkup,
                    iOSAppId: linkup);
              },
              child: Text('Cập nhật'))
        ]);
  }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('launch_image.png'),
      ),
    );
  }
}
