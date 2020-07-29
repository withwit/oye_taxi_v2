import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oye_taxi_v2/examples/load.dart';
import 'package:oye_taxi_v2/screens/overview.dart';
import '../requests/google_maps_requests.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Connect extends StatefulWidget {
  LatLng latLng1, latLng2;
  String dest;

  Connect({Key key, this.latLng1, this.latLng2, this.dest}) : super(key: key);

  @override
  _ConnecteState createState() => _ConnecteState(latLng1, latLng2, dest);
}

class _ConnecteState extends State<Connect> {
  LatLng latLng1, latLng2;
  String dest;
  _ConnecteState(this.latLng1, this.latLng2, this.dest);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        body: Map(latLng1, latLng2, dest));
  }
}

class Map extends StatefulWidget {
  LatLng latLng1, latLng2;
  String dest;
  Map(this.latLng1, this.latLng2, this.dest);

  @override
  _MapState createState() => _MapState(latLng1, latLng2, dest);
}

class _MapState extends State<Map> {
  GoogleMapController mapController;

  GeoPoint geoPoint;

  LatLng latLng1, latLng2;
  String dest;

  int time;

  String distanceInKm;
  double rate = 2.5;
  double price_min = 0.01;
  double price_max = 0.01;

  double d;

  _MapState(this.latLng1, this.latLng2, this.dest);
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};

  final _places = GoogleMapsPlaces(apiKey: apiKey);

  var _fromController = TextEditingController();

  var destinationController = TextEditingController();

  String userID = "5M2ymNcN2OajYrfLINCh";

  int mark_count = 0;
  @override
  void initState() {
    createRoute(latLng1, latLng2);
    _addMarker(latLng1);
    _addMarker(latLng2);
    _calc_distance(latLng1, latLng2);
    navigation_timer();
  }

  @override
  void dispose() {
    _polyLines.clear();
    _markers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    add_to_db(latLng2);
    Size deviceSize = MediaQuery.of(context).size;
    return ((latLng1 == null) && (latLng2 == null))
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
                    CameraPosition(target: latLng1, zoom: 12.0),
                onMapCreated: onCreated,
                myLocationEnabled: true,
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                markers: _markers,
                onCameraMove: _onCameraMove,
                polylines: _polyLines,
              ),
              new Positioned(
                bottom: 20.0,
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
                                      "${distanceInKm}KM",
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
                                    Text(
                                      "PRICE:  ₹${price_min.toStringAsPrecision(2)} - ₹${price_max.toStringAsPrecision(2)}",
                                      style: TextStyle(
                                          letterSpacing: 2.0,
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.w200),
                                    ),
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
                  child: Hero(
                    tag: "b",
                    child: FloatingActionButton(
                      elevation: 0.0,
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.keyboard_backspace,
                        size: 20.0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  Future<Timer> navigation_timer() async {
    if (latLng1 == null && latLng2 == null) {
    } else {
      return new Timer(Duration(seconds: 4), onDoneLoading);
    }
  }

  onDoneLoading() async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Overview(
              latLng1: latLng1,
              dest: dest,
            )));
  }

  void onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      // latLng1 = position.target;
    });
  }

  Future _addMarker(LatLng location) async {
    //  location =  (location == null ? LatLng(23.4358, 80.8463):location);

    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(location.latitude, location.longitude);
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(mark_count.toString()),
          position: location,
          draggable: true,
          infoWindow: InfoWindow(
              title: placemark[0].name, snippet: placemark[0].subLocality),
          icon: BitmapDescriptor.defaultMarker));
      mark_count++;
    });
  }

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
        (latLng2 == null ? LatLng(23.12831529469085, 79.8717156341757) : latLng2);

    print("_calc_distance");
    d = await Geolocator().distanceBetween(latLng1.latitude, latLng1.longitude,
            latLng2.latitude, latLng2.longitude) /
        1000;
    price_max = (d * (rate + 1.5));
    price_min = (d * (rate));
    distanceInKm = d.toStringAsFixed(2);

    print(distanceInKm);
    print(price_min);
    print(price_max);
  }

  void add_to_db(LatLng latLng2) {
    // double lat = latLng2.latitude== null ? 10.0:latLng2.latitude;
    // double lng = latLng2.longitude == null ?10.0:latLng2.longitude;
    dest == null ?? " ekta chowk";

    Firestore.instance.collection('live_locations').document(userID).setData({
      'location': latLng1,
      'to': dest.toString(),
      'from': dest.toString(),
      'distance': distanceInKm,
      'cost': price_max,
      'type': 'local',
      'num': 1,
      'requests1': "",
      'requests2': "",
      'time': DateTime.now().millisecondsSinceEpoch,
      'user_id': userID,
    });

    Firestore.instance
        .collection('users')
        .document(userID)
        .collection('current')
        .document('me')
        .setData({
      'location': GeoPoint(23.168833, 79.93353400000001),
      'to': dest.toString(),
      'from': dest.toString(),
      'distance': distanceInKm,
      'cost': price_max,
      'requests1': "",
      'requests2': "",
      'type': 'local',
      'user_id': userID,
    });
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
}
