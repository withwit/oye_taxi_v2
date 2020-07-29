import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:location/location.dart';

import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class Fire_Map extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: FireMap(),
    ));
  }
}

class FireMap extends StatefulWidget {
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;
  Location location = new Location();
  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  // Stateful Data
  BehaviorSubject<double> radius = BehaviorSubject(seedValue: 100.0);
  Stream<dynamic> query;

  // Subscription
  StreamSubscription subscription;

  final Set<Marker> _markers = {};

  var mark_count = 0;

  BitmapDescriptor myIcon;

  build(context) {
    return Stack(children: [
      GoogleMap(
        initialCameraPosition:
            CameraPosition(target: LatLng(23.4415, 79.9864), zoom: 15),
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        mapType: MapType.normal,
        compassEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
      Positioned(
          bottom: 50,
          right: 10,
          child: FlatButton(
              child: Icon(Icons.pin_drop, color: Colors.white),
              color: Colors.green,
              onPressed: _addGeoPoint)),
      Positioned(
          bottom: 50,
          left: 10,
          child: Slider(
            min: 100.0,
            max: 500.0,
            divisions: 4,
            value: radius.value,
            label: 'Radius ${radius.value}km',
            activeColor: Colors.green,
            inactiveColor: Colors.green.withOpacity(0.2),
            onChanged: _updateQuery,
          ))
    ]);
  }

  // Map Created Lifecycle Hook
  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  _addMarker(GeoPoint pos) {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(mark_count.toString()),
          position: LatLng(pos.latitude, pos.longitude),
          draggable: true,
          // infoWindow: InfoWindow(
          //     title: placemark[0].name, snippet: placemark[0].subLocality),
          // icon: BitmapDescriptor.defaultMarker,
          icon: myIcon));
    });
    mark_count++;

    //  MarkerOptions(
    //      position: mapController.cameraPosition.target,
    //      icon: BitmapDescriptor.defaultMarker,
    //      infoWindowText: InfoWindowText('Magic Marker', '🍄🍄🍄')
    //  );
  }

  _animateToUser() async {
    var pos = await location.getLocation();
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(pos.latitude, pos.longitude),
      zoom: 17.0,
    )));
  }

  // Set GeoLocation Data
  Future<DocumentReference> _addGeoPoint() async {
    var pos = await location.getLocation();
    GeoFirePoint point =
        geo.point(latitude: pos.latitude, longitude: pos.longitude);
    return firestore.collection('live_locations').add({
      'location': point.data,
      'user_id': 'Yay I can be queried!',
      'time': DateTime.now().millisecondsSinceEpoch,
      'from': 'From',
      'to': 'To',
      'distance': 10.0,
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print(documentList);
    _markers.clear();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.data['location']['geopoint'];
      double distance = document.data['distance'];

      _addMarker(pos);
    });
  }

  _startQuery() async {
    // Get users location
    var pos = await location.getLocation();
    double lat = pos.latitude;
    double lng = pos.longitude;

    // Make a referece to firestore
    var ref = firestore.collection('live_locations');
    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);

    // subscribe to query
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
          center: center, radius: rad, field: 'location', strictMode: true);
    }).listen(_updateMarkers);
  }

  _updateQuery(value) {
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    mapController.moveCamera(CameraUpdate.zoomTo(zoom));

    setState(() {
      radius.add(value);
    });
  }

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(38, 38)), 'assets/taxi.png')
        .then((onValue) {
      myIcon = onValue;
    });
    super.initState();
  }

  @override
  dispose() {
    //   subscription.cancel();
    super.dispose();
  }
}
