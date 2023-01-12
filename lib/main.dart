import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:validators/validators.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'animated_circle_widget.dart';
import 'blinking_circle_widget.dart';
import 'text_widget.dart';

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

  Widget SearchButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Colors.blue,
        onPrimary: Colors.white,
        shadowColor: Colors.blueAccent,
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        minimumSize: Size(200, 60),
      ),
      onPressed: () {},
      child: Text('Suche starten'),
    );
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
            SearchButton(),
            hspace(100),
            BlinkingCircle(radius: 50, text: '2m entfernt')
          ]),
        ),
      ),
    );
  }
}
