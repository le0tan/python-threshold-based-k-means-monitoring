import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:device_info/device_info.dart';

const String API_BASE_URL = "http://127.0.0.1:4004";
const int SENSITIVITY =
    5; // sensitivity in meters (moving how far would trigger an event to check its distance from the previous center)

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String locationString = "location goes here...";
  String thresholdString = "threshold not initialized...";
  String statusString = "not initialized";
  int threshold = 1;
  Position currentPosition;
  Position currentCenter;
  Future<String> _getId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("TKM Demo App"),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: Text("Show current location"),
              onPressed: () {
                Geolocator()
                    .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
                    .then((Position pos) {
                  setState(() {
                    currentPosition = pos;
                    locationString = currentPosition.toString();
                  });
                });
              },
            ),
            RaisedButton(
              child: Text("Initialize"),
              onPressed: () async {
                var geolocator = Geolocator();
                try {
                  // Initialize current position
                  geolocator
                      .getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high)
                      .then((Position pos) {
                    setState(() {
                      currentPosition = pos;
                      locationString = currentPosition.toString();
                      currentCenter = currentPosition;
                    });
                  });
                  // Set up FCM
                  final FirebaseMessaging _firebaseMsg = FirebaseMessaging();
                  print(await _firebaseMsg.getToken());
                  _firebaseMsg.configure(
                      onMessage: (Map<String, dynamic> msg) async {
                    // Write what you want to do upon receiving the message here...
                    print("onMessage: $msg");
                    setState(() {
                      threshold = int.parse(msg['body']);
                    });
                  });
                  if (Platform.isIOS) {
                    StreamSubscription iosSubscription = _firebaseMsg
                        .onIosSettingsRegistered
                        .listen((data) async {});
                    _firebaseMsg.requestNotificationPermissions(
                        IosNotificationSettings());
                  }
                  // Initialize TKM related stuff
                  var dio = Dio();

                  dio
                      .post(API_BASE_URL + "/api/init_location",
                          data: {
                            'id': await _getId(),
                            'lat': currentPosition.latitude,
                            'lng': currentPosition.longitude
                          },
                          options: Options(contentType: ContentType.json))
                      .then((Response resp) {
                    setState(() {
                      threshold = int.parse(resp.data);
                      thresholdString = threshold.toString() + 'm';
                    });
                  });
                } catch (e) {
                  threshold = 1;
                  thresholdString = '1m (running on debug mode)';
                }
                // A stream subscription that triggers every [SENSITIVITY]
                var locationOptions = LocationOptions(
                    accuracy: LocationAccuracy.high,
                    distanceFilter: SENSITIVITY);
                StreamSubscription<Position> positionStream = geolocator
                    .getPositionStream(locationOptions)
                    .listen((Position position) async {
                  if (position != null &&
                      await geolocator.distanceBetween(
                              position.latitude,
                              position.longitude,
                              currentCenter.latitude,
                              currentCenter.longitude) >
                          threshold) {
                    geolocator
                        .getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high)
                        .then((Position pos) {
                      setState(() {
                        currentPosition = pos;
                        locationString = currentPosition.toString();
                        currentCenter = currentPosition;
                      });
                    });
                    var dio = Dio();
                    dio
                        .post(API_BASE_URL + "/api/update_location",
                            data: {
                              'id': await _getId(),
                              'lat': currentPosition.latitude,
                              'lng': currentPosition.longitude
                            },
                            options: Options(contentType: ContentType.json))
                        .then((Response resp) {
                      setState(() {
                        threshold = int.parse(resp.data);
                        thresholdString = threshold.toString() + 'm';
                      });
                    });
                  }
                });
                setState(() {
                  statusString = thresholdString == '1m (running on debug mode)'
                      ? 'running (debug mode)'
                      : 'running';
                });
              },
            ),
            Text('Location: ' + locationString),
            Text('Threshold: ' + thresholdString),
            Text('Status: ' + statusString)
          ],
        )));
  }
}
