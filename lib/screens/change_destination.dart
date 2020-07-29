import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oye_taxi_v2/screens/home.dart';
import '../requests/google_maps_requests.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:oye_taxi_v2/examples/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Change_Location extends StatefulWidget {
  var loc_id;

  Change_Location(this.loc_id, {Key key, this.title}) : super(key: key);

  final String title;

  @override
  _Change_LocationState createState() => _Change_LocationState(loc_id);
}

class _Change_LocationState extends State<Change_Location> {
  var loc_id;

  _Change_LocationState(this.loc_id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return MyHomePage();
                },
              ),
            );
          },
        ),
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        body: Map(loc_id));
  }
}

class Map extends StatefulWidget {
  var loc_id;

  Map(this.loc_id);

  @override
  _MapState createState() => _MapState(loc_id);
}

class _MapState extends State<Map> {
  GoogleMapController mapController;
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();

  static LatLng initialPosition;
  LatLng _lastPosition = initialPosition;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};

  final _places = GoogleMapsPlaces(apiKey: apiKey);

  var destinationController = TextEditingController();

  String userID = "5M2ymNcN2OajYrfLINCh";
  _MapState(this.userID);
  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bloc = LocationProvider.of(context);

    return initialPosition == null
        ? Container(
            alignment: Alignment.center,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Stack(
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
                top: 120.0,
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
                  child: TextField(
                    cursorWidth: 0.0,
                    cursorColor: Colors.transparent,
                    controller: destinationController,
                    textInputAction: TextInputAction.go,
                    onTap: () async {
                      _markers.clear();
                      Prediction p = await PlacesAutocomplete.show(
                        context: context,
                        apiKey: apiKey,
                        mode: Mode.overlay,
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
                      sendRequest(response.result.formattedAddress,
                          response.result.reference);
                      destinationController.text =
                          response.result.formattedAddress;
                      initialPosition = LatLng(location.lat, location.lng);
                      _addMarker(initialPosition, destinationController.text,
                          destinationController.text);
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
                      hintText: "Your Location ?",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
                    ),
                  ),
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
        hintText: "pick up",
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
      ),
      controller: destinationController,
      onTap: () async {
        //    Navigator.push(
        //      context,
        //      MaterialPageRoute(
        //        builder: (context) {
        //          print(initialPosition.longitude);
        //          return ChangeLocation(initialPosition.latitude , initialPosition.longitude);
        //        },
        //      ),
        //    );
      },
    );
  }

  void onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _lastPosition = position.target;
    });
  }

  void _addMarker(LatLng location, String address, String adrAddress) {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(userID.toString()),
          position: location,
          draggable: true,
          infoWindow: InfoWindow(title: address, snippet: adrAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(50.0)));

      Firestore.instance
          .collection('users')
          .document(userID)
          .collection('myLocation')
          .document(userID)
          .setData(
        {
          "geo": GeoPoint(location.latitude, location.longitude),
          "id": userID,
        },
      );
    });
  }

  void createRoute(String encondedPoly) {
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

  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    _markers.add(Marker(
        markerId: MarkerId(userID),
        position: LatLng(position.latitude, position.longitude),
        draggable: true,
        infoWindow: InfoWindow(
            title: placemark[0].name, snippet: placemark[0].subLocality),
        icon: BitmapDescriptor.defaultMarkerWithHue(50.0)));

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

    setState(() {
      initialPosition = LatLng(position.latitude, position.longitude);
      destinationController.text = placemark[0].name;
    });
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
