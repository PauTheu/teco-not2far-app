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
      title: 'Not2Far',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        primaryColor: Colors.deepOrangeAccent,

        textTheme: TextTheme(
          headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: MyHomePage(title: 'Not2Far'),
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




  int criticalDistance = 500;
  double currentDistance = 0;

  double homelon;
  double homelat;

  double latitude;
  double longitude;

  double speed = 0;

  double meter = 0;

  int anzIcon = 0;

  BluetoothDevice tecoDevice;
  StreamSubscription<ScanResult> sub;
  bool connectionStatus = false;

  BluetoothCharacteristic btc;




  void setCurrentLocation() async {
    LocationData currentLocation;
    var location = new Location();
    try {
      currentLocation = await location.getLocation();
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        print('Permission denied');
      }
      currentLocation = null;
    }
    setState(() {
      homelat = currentLocation.latitude;
      homelon = currentLocation.longitude;
    });
  }



















  void initState() {
    super.initState();
    setCurrentLocation();
    calculate();
    startScan();

  }

  Widget hspace(double x) {
    return Container(height: x);
  }

  Widget wspace(double x) {
    return Container(width: x);
  }

  Widget output1() {
    return Text('critical distance: $criticalDistance');
  }

  Widget output2() {
    return Text('current distance: $currentDistance');
  }

  Widget row1() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RaisedButton(

          child: Text('Set Location'),
          onPressed: setCurrentLocation,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
            splashColor: Colors.deepOrangeAccent,
        ),
        wspace(50),
        Text('Lat: $homelat\nLon: $homelon'),
      ],
    );
  }

  Widget input1() {
    return TextFormField(

      keyboardType: TextInputType.number,
      decoration: new InputDecoration(
          labelText: "Please enter distance in meter",
          fillColor: Colors.white,
          border: new OutlineInputBorder(
            borderRadius: new BorderRadius.circular(25.0),
            borderSide: new BorderSide(
            ),
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
              criticalDistance = int.parse(value);
            },
          );
          formKey.currentState.reset();
        }
      },
    );
  }

  Widget output3() {
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

  void calculate() {
    var location = new Location();
    location.changeSettings(
      accuracy: LocationAccuracy.HIGH,
      interval: 2,
    );
    location.onLocationChanged().listen((LocationData currentLocation) async {
      int anzIconNeu = 0;
      latitude = currentLocation.latitude;
      longitude = currentLocation.longitude;
      Distance distance = new Distance();

      setState(() {
        currentDistance = distance(
            new LatLng(homelat, homelon), new LatLng(latitude, longitude));
      });

      if (currentDistance >= criticalDistance) {
        anzIconNeu = 1;
        // btc.write([0xFF, 0x00, 0x00, 0x00]);

      }
      if (currentDistance >= criticalDistance * 1.25) {
        anzIconNeu = 2;
        // btc.write([0xFF, 0xFF, 0x00, 0x00]);

      }
      if (currentDistance >= criticalDistance * 1.5) {
        anzIconNeu = 3;
        // btc.write([0xFF, 0xFF, 0xFF, 0x00]);
      }
      if (currentDistance >= criticalDistance * 2) {
        anzIconNeu = 4;
        // btc.write([0xFF, 0xFF, 0xFF, 0xFF]);
      }

      if (anzIconNeu != anzIcon) {
        setState(() {
          anzIcon = anzIconNeu;
        });

        if (anzIconNeu == 0) {
          await btc.write([0x00, 0x00, 0x00, 0x00]);
        } else if (anzIconNeu == 1) {
          await btc.write([0xFF, 0x00, 0x00, 0x00]);
        } else if (anzIconNeu == 2) {
          await btc.write([0xFF, 0xFF, 0x00, 0x00]);
        } else if (anzIconNeu == 3) {
          await btc.write([0xFF, 0xFF, 0xFF, 0x00]);
        } else if (anzIconNeu == 4) {
          await btc.write([0xFF, 0xFF, 0xFF, 0xFF]);
        }
      }
    });
  }

  void startScan() {
    sub = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name.contains('TECO')) {
        setState(() {
          tecoDevice = scanResult.device;
          sub.cancel();
        });
      }
    });
  }

  Future connect() async {
    await tecoDevice.connect();
    setState(() {
      connectionStatus = true;
    });

    List<BluetoothService> services = await tecoDevice.discoverServices();
    services.forEach((BluetoothService service) async {
      if (service.uuid.toString() == '713d0000-503e-4c75-ba94-3148f18d941e') {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          if (c.uuid.toString() == '713d0003-503e-4c75-ba94-3148f18d941e') {
            btc = c;
          }

        }
      }
    });
  }


  void disconnect() {
    if (tecoDevice != null) {
      tecoDevice.disconnect();
    }
    setState(() {
      connectionStatus = false;
    });
  }

  Widget showinfo() {
    String text = '';
    String status = 'disconnected';
    if (connectionStatus) status = "connected";

    if (tecoDevice != null) text = tecoDevice.name;
    return Text('tecoDevice = $text \nstatus = $status');
  }









  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        

        title: Text(widget.title), actions: <Widget>[
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

            showinfo(),
            row1(),
            hspace(20),
            input1(),
            hspace(20),
            output1(),
            hspace(20),

            output2(),
            output3(),

          ]),
        ),
      ),
    );
  }
}