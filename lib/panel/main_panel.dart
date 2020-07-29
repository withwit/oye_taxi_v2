import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oye_taxi_v2/examples/load.dart';
import 'package:oye_taxi_v2/screens/home.dart';
import 'package:rxdart/rxdart.dart';
import '../requests/google_maps_requests.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

BitmapDescriptor myIcon;

class Main_Panel extends StatefulWidget {
  @override
  Main_PanelState createState() => Main_PanelState();
}

class Main_PanelState extends State<Main_Panel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        body: Map());
  }
}

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  GoogleMapController mapController;

  GeoPoint geoPoint;

  LatLng latLng1;
  String dest;

  int time;

  String distanceInMeters;
  double rate = 2.5;
  double price_min;
  double price_max;

  double d;

  Stream<List<DocumentSnapshot>> stream;
  var radius = BehaviorSubject(seedValue: 100.0);
  Geoflutterfire geo;

  GoogleMapsServices _googleMapsServices = GoogleMapsServices();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  String userID = "5M2ymNcN2OajYrfLINCh";
  int mark_count = 0;

  var geolocator = Geolocator();
  var locationOptions =
      LocationOptions(accuracy: LocationAccuracy.high, timeInterval: 3000);

  MarkerId my_marker_id = MarkerId("1011");

  int _count = 0;

  @override
  void initState() {
    _getUserLocation();

    geo = Geoflutterfire();
    GeoFirePoint center = geo.point(latitude: 21.0540, longitude: 79.0203);
    stream = radius.switchMap((rad) {
      var collectionReference = Firestore.instance.collection('live_user_loc');
      //          .where('name', isEqualTo: 'darshan');
      return geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: rad, field: 'location');
    });

    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(38, 38)), 'assets/taxi.png')
        .then((onValue) {
      myIcon = onValue;
    });
  }

// @override
// void dispose() {
// //  _markers.clear();
//   super.dispose();
// }

  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return (latLng1 == null)
        ? new Container(
            alignment: Alignment.bottomCenter,
            child: Center(
              child: new Ripples(
                child: Icon(
                  Icons.local_taxi,
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            ),
          )
        : new Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: latLng1, zoom: 20.0),
                onMapCreated: onCreated,
                myLocationEnabled: true,
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                markers: _markers,
                onCameraMove: _onCameraMove,
              ),
              new Positioned(
                top: 40.0,
                right: 0.0,
                child: new Ripples(
                    size: 38.0,
                    color: Colors.green,
                    child: Text(
                      "OYE!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2),
                    )),
              ),
              new Positioned(
                bottom: 50.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: deviceSize.height * 0.25,
                    width: deviceSize.width * 0.963,
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 2.0,
                            width: deviceSize.width * 0.8,
                            child: new LinearProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              backgroundColor: Colors.amber,
                            ),
                          ),
                          new Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(
                                      "${distanceInMeters}KM",
                                      style: TextStyle(
                                          letterSpacing: 2.0,
                                          fontWeight: FontWeight.w200,
                                          fontSize: 25.0),
                                    ),
                                    //    Text("   APPROX",style: TextStyle(letterSpacing: 2.5,fontSize: 25.0,fontWeight: FontWeight.w300),),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          new Flexible(
                            child: new Container(
                              padding: new EdgeInsets.only(right: 13.0),
                              child: Text(
                                "${dest.toString()}",
                                softWrap: true,
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18.0,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w300),
                              ),
                            ),
                          ),
                          new Padding(
                            padding:
                                const EdgeInsets.only(left: 30.0, right: 30.0),
                            child: Divider(
                              height: 0.0,
                            ),
                          ),
                          SizedBox(
                            height: 4.0,
                          ),
                          new Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    //  Text(
                                    //    "PRICE:  ₹${price_min.toStringAsPrecision(2)} - ₹${price_max.toStringAsPrecision(2)}",
                                    //    style: TextStyle(
                                    //        letterSpacing: 2.0,
                                    //        fontSize: 25.0,
                                    //        fontWeight: FontWeight.w200),
                                    //  ),
                                    //    Text("   APPROX",style: TextStyle(letterSpacing: 2.5,fontSize: 25.0,fontWeight: FontWeight.w300),),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 30.0, right: 30.0),
                            child: Divider(
                              height: 0.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              new Positioned(
                bottom: 40.0,
                left: 20.0,
                child: new Container(
                  height: 40.0,
                  width: 40,
                  child: FloatingActionButton(
                    elevation: 0.0,
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.keyboard_backspace,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      print(my_marker_id.value);

                      _markers.clear();
                      // createRoute(LatLng(25.199327, 79.91956),
                      //     LatLng(25.4484257, 78.5684594));
                      //   _calc_distance(latLng1, latLng2);
                    },
                  ),
                ),
              ),
            ],
          );
  }

  onDoneLoading() async {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MyHomePage()));
  }

  void onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      stream.listen((List<DocumentSnapshot> documentList) {
        _updateMarkers(documentList);
      });
    });
  }

  void _addMarker(double lat, double lng, String s, int n) {
    setState(() {
      n = n == null ? 0 : n;
      switch (s) {
        case 'me':
          _markers.add(Marker(
            markerId: my_marker_id,
            position: LatLng(lat, lng),
            draggable: false,
            infoWindow:
                InfoWindow(title: "Me", snippet: 'snippets', onTap: () {}),
            //  icon: myIcon,
            icon: BitmapDescriptor.defaultMarker,
            // icon: myIcon
          ));
          break;
        case 'local':
          _markers.add(Marker(
            markerId: MarkerId(mark_count.toString()),
            position: LatLng(lat, lng),
            draggable: false,
            infoWindow:
                InfoWindow(title: s, snippet: " $n passengers ", onTap: () {}),
            icon: BitmapDescriptor.defaultMarker,
            // icon: myIcon
          ));
          break;
        case 'booked':
          _markers.add(Marker(
            markerId: MarkerId(mark_count.toString()),
            position: LatLng(lat, lng),
            draggable: false,
            infoWindow: InfoWindow(title: s, snippet: 'snippets', onTap: () {}),
            icon: BitmapDescriptor.defaultMarker,
            // icon: myIcon
          ));
          break;
        case 'tip':
          _markers.add(Marker(
            markerId: MarkerId(mark_count.toString()),
            position: LatLng(lat, lng),
            draggable: false,
            infoWindow: InfoWindow(title: s, snippet: 'snippets', onTap: () {}),
            icon: BitmapDescriptor.defaultMarker,
            // icon: myIcon
          ));
          break;
        case 'booked':
          _markers.add(Marker(
            markerId: MarkerId(mark_count.toString()),
            position: LatLng(lat, lng),
            draggable: false,
            infoWindow: InfoWindow(title: s, snippet: 'snippets', onTap: () {}),
            icon: BitmapDescriptor.defaultMarker,
            // icon: myIcon
          ));
          break;
        default:
          print('It\'s weekend');
      }
    });
    mark_count++;
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    _markers.clear();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint point = document.data['location']['geopoint'];
      String type = document.data['type'];
      int num = document.data['num'];
      _addMarker(point.latitude, point.longitude, type, num);
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      latLng1 = position.target;
    });
  }

  //Future _addMarker(LatLng location) async {
  //  //  location =  (location == null ? LatLng(23.4358, 80.8463):location);

  //  List<Placemark> placemark = await Geolocator()
  //      .placemarkFromCoordinates(location.latitude, location.longitude);
  //  setState(() {
  //    _markers.add(Marker(
  //        markerId: MarkerId(mark_count.toString()),
  //        position: location,
  //        draggable: true,
  //        infoWindow: InfoWindow(
  //            title: placemark[0].name, snippet: placemark[0].subLocality),
  //        icon: BitmapDescriptor.defaultMarker));
  //    mark_count++;
  //  });
  //}

  Future createRoute(LatLng latLng1, LatLng latLng2) async {
    latLng2 =
        (latLng2 == null ? LatLng(23.168833, 79.93353400000001) : latLng2);
    print(latLng1);
    print("^^^^^^^^^^^^^^^^^^");
    print("lllll");
    print(latLng2);
    print("lllll");

    String route =
        await _googleMapsServices.getRouteCoordinates(latLng1, latLng2);
    setState(() {
      _polyLines.add(Polyline(
          consumeTapEvents: true,
          polylineId:
              PolylineId(DateTime.now().millisecondsSinceEpoch.toString()),
          width: 10,
          points: convertToLatLng(decodePoly(route)),
          color: Colors.black));
      mark_count++;
    });
  }

  Future _calc_distance(LatLng latLng1, LatLng latLng2) async {
    latLng2 =
        (latLng2 == null ? LatLng(23.168833, 79.93353400000001) : latLng2);

    print("_calc_distance");
    d = await Geolocator().distanceBetween(latLng1.latitude, latLng1.longitude,
            latLng2.latitude, latLng2.longitude) /
        1000;
    price_max = (d * (rate + 1.5));
    price_min = (d * (rate));
    distanceInMeters = d.toStringAsFixed(2);

    print(distanceInMeters);
    print(price_min);
    print(price_max);
  }

/*
* [12.12, 312.2, 321.3, 231.4, 234.5, 2342.6, 2341.7, 1321.4]
* (0-------1-------2------3------4------5-------6-------7)
* */

//  this method will convert list of doubles into latlng
  List<LatLng> convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
// repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negetive then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

/*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latLng1 = LatLng(position.latitude, position.longitude);
    });

    _markers.add(Marker(
      markerId: my_marker_id,
      position: LatLng(position.latitude, position.longitude),
      draggable: false,
      infoWindow: InfoWindow(title: "Me", snippet: 'snippets', onTap: () {}),
      //  icon: myIcon,
      icon: BitmapDescriptor.defaultMarker,
      // icon: myIcon
    ));

    //  StreamSubscription<Position> positionStream = geolocator
    geolocator.getPositionStream(locationOptions).listen((Position position) {
      //   _markers.clear();

      // remove_marker(my_marker_id);
      _addMarker(position.latitude, position.longitude, 'me', 0);
      //  stream.listen((List<DocumentSnapshot> documentList) {
      //    _updateMarkers(documentList);
      //  });
      print(my_marker_id.value.toString());
      print('updated');
    });
  }

  Future remove_marker(MarkerId my_marker_id) async {
    await _markers.remove(my_marker_id.value);
  }
}
