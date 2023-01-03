import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:latlong/latlong.dart';
import 'package:validators/validators.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESL Suche',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          caption: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          bodyText1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: MyHomePage(title: 'ESL Suche'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final formKey = GlobalKey<FormState>();
  FlutterBlue flutterBlue = FlutterBlue.instance;

  String tagMac;
  int rssi;

  double currentDistance = 0;

  double homelon;
  double homelat;

  String proximity;

  int anzIcon = 1;

  BluetoothDevice eslDevice;
  StreamSubscription<ScanResult> sub;
  bool connectionStatus = false;

  BluetoothCharacteristic btc;

  void initState() {
    super.initState();
  }

  Widget hspace(double x) {
    return Container(height: x);
  }

  Widget wspace(double x) {
    return Container(width: x);
  }

  Widget RssiValueWidget() {
    return Text('Rssi: -40');
  }

  Widget ProximityValueWidget() {
    return Text('Proximity: nah');
  }

  Widget startSearchButtonWidget() {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(16.0),
        textStyle: const TextStyle(fontSize: 20),
      ),
      onPressed: startSearch,
      child: const Text('Suche starten'),
    );
  }

  Widget tagInputWidget() {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: new InputDecoration(
        labelText: "Tag MAC",
        fillColor: Colors.white,
        border: new OutlineInputBorder(
          borderRadius: new BorderRadius.circular(25.0),
          borderSide: new BorderSide(width: 2),
        ),
      ),
      validator: (value) {
        if (!isNumeric(value)) {
          return 'Please enter an integer';
        }
      },
      onFieldSubmitted: (value) {
        if (formKey.currentState.validate()) {
          formKey.currentState.save();
          setState(
            () {
              tagMac = value;
            },
          );
          formKey.currentState.reset();
        }
      },
    );
  }

  Widget DistanceIconWidget() {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          anzIcon >= 1 ? Icon(Icons.directions_run) : Container(),
          anzIcon >= 2 ? Icon(Icons.directions_run) : Container(),
          anzIcon >= 3 ? Icon(Icons.directions_run) : Container(),
          anzIcon >= 4 ? Icon(Icons.directions_run) : Container(),
        ],
      ),
    );
  }

/* if (anzIconNeu == 0) {
  await btc.write([0x00, 0x00, 0x00, 0x00]);
} else if (anzIconNeu == 1) {
  await btc.write([0xFF, 0x00, 0x00, 0x00]);
} else if (anzIconNeu == 2) {
  await btc.write([0xFF, 0xFF, 0x00, 0x00]);
} else if (anzIconNeu == 3) {
  await btc.write([0xFF, 0xFF, 0xFF, 0x00]);
} else if (anzIconNeu == 4) {
  await btc.write([0xFF, 0xFF, 0xFF, 0xFF]); */

  void startSearch() {
    sub = flutterBlue.scan().listen((scanResult) {
      print(scanResult);
      if (scanResult.device.name.contains(tagMac)) {
        setState(() {
          eslDevice = scanResult.device;
          sub.cancel();
        });
        connect();
      }
    });
  }

  Future connect() async {
    await eslDevice.connect();
    setState(() {
      connectionStatus = true;
    });

    List<BluetoothService> services = await eslDevice.discoverServices();
    services.forEach((BluetoothService service) async {
      print(service);
    });
  }

  void disconnect() {
    if (eslDevice != null) {
      eslDevice.disconnect();
    }
    setState(() {
      connectionStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.bluetooth),
          onPressed: () {
            if (connectionStatus) {
              disconnect();
            } else {
              connect();
            }
          },
        )
      ]),
      body: Container(
        margin: EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(children: <Widget>[
            hspace(20),
            tagInputWidget(),
            hspace(20),
            startSearchButtonWidget(),
            hspace(20),
            RssiValueWidget(),
            hspace(20),
            ProximityValueWidget(),
            hspace(20),
            DistanceIconWidget(),
          ]),
        ),
      ),
    );
  }
}
