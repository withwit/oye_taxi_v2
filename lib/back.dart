/*

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oye_taxi_v1/screens/change_location.dart';
// ignore: uri_does_not_exist
import '../requests/google_maps_requests.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:oye_taxi_v1/examples/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyHomePage extends StatefulWidget {
  String ref;

  MyHomePage({Key key, this.ref, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(ref);
}

class _MyHomePageState extends State<MyHomePage> {
  String ref;
  _MyHomePageState(this.ref);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        body: Map(ref));
  }
}

class Map extends StatefulWidget {
  String ref;
  Map(this.ref);

  @override
  _MapState createState() => _MapState(ref);
}

class _MapState extends State<Map> {
  GoogleMapController mapController;
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  GeoPoint geoPoint;
  static LatLng initialPosition;

  String ref;

  int count;
  _MapState(this.ref);

  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};

  final _places = GoogleMapsPlaces(apiKey: apiKey);

  var _fromController = TextEditingController();

  var destinationController = TextEditingController();

  String userID = "5M2ymNcN2OajYrfLINCh";

  var mkk;

  @override
  void initState() {
    ref == 'changed'
        ? Firestore.instance
        .collection('users')
        .document(userID)
        .collection('myLocation')
        .document(userID)
        .get()
        .then((DocumentSnapshot) {
      setState(() {
        print("database location VVVVVVVVVVVVVV");
        print(ref);
        geoPoint = DocumentSnapshot.data['geo'];
        initialPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
        print(geoPoint.longitude.toString());
      });
    })
        : null;

    initialPosition.toString() == null
        ? _getUserLocation(ref)
        : Firestore.instance
        .collection('users')
        .document(userID)
        .collection('myLocation')
        .document(userID)
        .get()
        .then((DocumentSnapshot) {
      setState(() {
        print("AAAAAAAAAAAAAAAAAAAssssssssssssssaaaaaaaaaaaaaaaaa");
        print( initialPosition.toString());
        geoPoint = DocumentSnapshot.data['geo'];
        initialPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
      });
    });

    initialPosition == null ? null : fetch_markers();
  }

  fetch_markers() {
    Firestore.instance
        .collection('users')
        .document(userID)
        .collection('myLocation')
        .getDocuments()
        .then((docs) {
      if (docs.documents.isNotEmpty) {
        for (int i = 0; i < docs.documents.length; i++) {
          initMarker(docs.documents[i].data);
        }
      }
    });
    print('FETCHHHHHHHHHHHHHHHHHH');
  }

  Future initMarker(data) async {
    GeoPoint gp = data['geo'];
    List<Placemark> placemark =
    await Geolocator().placemarkFromCoordinates(gp.latitude, gp.longitude);
    // creating a new MARKER
    _markers.add(Marker(
        markerId: MarkerId("custom"),
        position: LatLng(gp.latitude, gp.longitude),
        draggable: false,
        infoWindow: InfoWindow(
            title: placemark[0].name, snippet: placemark[0].locality),
        icon: BitmapDescriptor.defaultMarkerWithHue(50.0)));

    _fromController.text = placemark[0].name;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final bloc = LocationProvider.of(context);

    return initialPosition == null
        ? new Container(
      alignment: Alignment.bottomCenter,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    )
        : new Stack(
      children: <Widget>[
        GoogleMap(
          initialCameraPosition:
          CameraPosition(target: initialPosition, zoom: 12.0),
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
          top: 130.0,
          right: 15.0,
          left: 15.0,
          child: Container(
            height: 50.0,
            width: double.infinity,
            decoration: new BoxDecoration(
              borderRadius: BorderRadius.circular(3.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey,
                    offset: Offset(1.0, 5.0),
                    blurRadius: 10,
                    spreadRadius: 3)
              ],
            ),
            child: _searchFieldFrom(context, bloc),
          ),
        ),
        new Positioned(
          top: 200.0,
          right: 15.0,
          left: 15.0,
          child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: new BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      offset: Offset(1.0, 5.0),
                      blurRadius: 10,
                      spreadRadius: 3)
                ],
              ),
              child: _searchFieldTo(context, bloc)
          ),
        ),
      ],
    );
  }

  Widget _searchFieldFrom(BuildContext context, LocationBloc bloc) {
    return new TextField(
      cursorColor: Colors.black,
      decoration: InputDecoration(
        icon: Container(
          margin: EdgeInsets.only(left: 20, top: 5),
          width: 10,
          height: 10,
          child: Icon(
            Icons.location_on,
            color: Colors.black,
          ),
        ),
        hintText: "Pickup Location",
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
      ),
      controller: _fromController,
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Change_Location(userID);
            },
          ),
        );
      },
    );
  }

  Widget _searchFieldTo(BuildContext context, LocationBloc bloc) {
    return new TextField(
      cursorColor: Colors.black,
      controller: destinationController,
      textInputAction: TextInputAction.go,
      onTap: () async {
        Prediction p = await PlacesAutocomplete.show(
          location: Location(initialPosition.latitude,
              initialPosition.longitude),
          context: context,
          apiKey: apiKey,
          mode: Mode.fullscreen,
          language: "en",
        );

        PlacesDetailsResponse response =
        await _places.getDetailsByPlaceId(p.placeId);
        var location = response.result.geometry.location;
        var latLng = LatLng(location.lat, location.lng);
        bloc.changeLocationString(
            response.result.formattedAddress);
        bloc.changeLocationLatLng(latLng);
        destinationController.text =
            response.result.formattedAddress;
        await sendRequest(response.result.formattedAddress,
            response.result.reference);
      },
      decoration: InputDecoration(
        icon: Container(
          margin: EdgeInsets.only(left: 20, top: 5),
          width: 10,
          height: 10,
          child: Icon(
            Icons.local_taxi,
            color: Colors.black,
          ),
        ),
        hintText: "Destination ?",
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
      ),
    );
  }


  void onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      initialPosition = position.target;
    });
  }

  void _addMarker(LatLng location, String address, String adrAddress) {
    setState(() {
      ref == null ? print(_markers.last.markerId.value.toString()) : null;
      ref == null
          ? print("PPPPPPPPPPPPPPOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOooo")
          : null;
      _markers.last.markerId.value.toString() == userID
          ? print('NOPE')
          : _markers.clear();

      _markers.add(Marker(
          markerId: MarkerId(_markers.last.markerId.value.toString() == userID
              ? 'custom'
              : userID),
          position: location,
          draggable: true,
          infoWindow: InfoWindow(title: address, snippet: adrAddress),
          icon: BitmapDescriptor.defaultMarker));
    });
  }

  void createRoute(String encondedPoly) {
    print(_markers.last.markerId);
    print("oooooooooooooooooooo");

    setState(() {
      _polyLines.add(Polyline(
          polylineId: PolylineId(userID.toString()),
          width: 10,
          points: convertToLatLng(decodePoly(encondedPoly)),
          color: Colors.black));
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

  void _getUserLocation(String ref) async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    _markers.add(Marker(
        markerId: MarkerId(_markers.last.markerId.value != 'custom'
            ? userID.toString()
            : '${userID + '1'}'),
        position: LatLng(position.latitude, position.longitude),
        draggable: true,
        infoWindow: InfoWindow(
            title: placemark[0].name, snippet: placemark[0].subLocality),
        icon: BitmapDescriptor.defaultMarkerWithHue(50.0)));

    setState(() {
      initialPosition = LatLng(position.latitude, position.longitude);
      _fromController.text = placemark[0].name;
    });
    print('FETCHING USRE LOCATIOnnnnnnnnnnnnnnnnnn');
    print(userID);
    print('FETCHING USRE LOCATIOnnnnnnnnnnnnnnnnnn');
    print(ref);

    Firestore.instance
        .collection('users')
        .document(userID)
        .collection('myLocation')
        .document(userID)
        .setData(
      {
        "geo": GeoPoint(position.latitude, position.longitude),
        "id": userID,
      },
    );
  }

  void sendRequest(String intendedLocation, String adrAddress) async {
    List<Placemark> placemark =
    await Geolocator().placemarkFromAddress(intendedLocation);
    double latitude = placemark[0].position.latitude;
    double longitude = placemark[0].position.longitude;
    LatLng destination = LatLng(latitude, longitude);
    String adrAddress;
    _addMarker(destination, intendedLocation, adrAddress);
    String route = await _googleMapsServices.getRouteCoordinates(
        initialPosition, destination);
    createRoute(route);
  }
}

*/
