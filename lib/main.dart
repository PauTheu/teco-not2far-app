import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:latlong/latlong.dart';
import 'package:validators/validators.dart';

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
  String in1 = '';
  double homelon;
  double homelat;

  double latitude;
  double longitude;

  double speed = 0;

  double meter = 0;

  int anzIcon = 0;

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
  }

  Widget hspace(double x) {
    return Container(height: x);
  }

  Widget wspace(double x) {
    return Container(width: x);
  }

  Widget output1() {
    return Text('critical distance: $in1');
  }

  Widget output2() {
    return Text('current distance: $meter');
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
        Text('$homelat / $homelon'),
      ],
    );
  }

  Widget input1() {
    return TextFormField(

      keyboardType: TextInputType.number,
      decoration: new InputDecoration(
          labelText: "Please enter Distance in meter",
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
              in1 = value;
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
    location.onLocationChanged().listen((LocationData currentLocation) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
        speed = (currentLocation.speed * 3.6);
        Distance distance = new Distance();
        meter = distance(
            new LatLng(homelat, homelon), new LatLng(latitude, longitude));
        int critical = int.parse(in1);
        anzIcon = 0;
        if (meter > critical) {
          anzIcon = 1;
        }
        if (meter > critical * 1.25) {
          anzIcon = 2;
        }
        if (meter > critical * 1.5) {
          anzIcon = 3;
        }
        if (meter > critical * 2) {
          anzIcon = 4;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: Container(

        margin: EdgeInsets.all(20.0),
        child: Form(

          key: formKey,
          child: Column(children: <Widget>[

            hspace(30),
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