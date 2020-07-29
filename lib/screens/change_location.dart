import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oye_taxi_v2/screens/home.dart';
import '../requests/google_maps_requests.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:oye_taxi_v2/examples/location_provider.dart';

class Change_Location extends StatefulWidget {
  LatLng initialPosition;

  Change_Location(this.initialPosition, {Key key, this.title})
      : super(key: key);

  final String title;

  @override
  _Change_LocationState createState() => _Change_LocationState(initialPosition);
}

class _Change_LocationState extends State<Change_Location> {
  LatLng initialPosition;

  _Change_LocationState(this.initialPosition);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        body: Map(initialPosition));
  }
}

class Map extends StatefulWidget {
  LatLng initialPosition;

  Map(this.initialPosition);

  @override
  _MapState createState() => _MapState(initialPosition);
}

class _MapState extends State<Map> {
  GoogleMapController mapController;

  LatLng initialPosition = LatLng(23.1998661, 79.91882399999997);

  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};

  final _places = GoogleMapsPlaces(apiKey: apiKey);

  var destinationController = TextEditingController();

  LatLng _lastPosition;

  CameraPosition camPosition;

  LatLng latLng;

  _MapState(this.initialPosition);
  @override
  void initState() {
    super.initState();
    _setCurrentLocationMarker(initialPosition);
  }

  @override
  void dispose() {
    destinationController.dispose();
    super.dispose();
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
                    CameraPosition(target: initialPosition, zoom: 18.0),
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
                child: new Container(
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
                    child: new RaisedButton(
                        child: Text(destinationController.text),
                        elevation: 0.0,
                        color: Colors.transparent,
                        onPressed: () async {
                          Prediction p = await PlacesAutocomplete.show(
                            context: context,
                            apiKey: apiKey,
                            mode: Mode.overlay,
                            language: "en",
                            radius: 1000,
                          );

                          PlacesDetailsResponse response =
                              await _places.getDetailsByPlaceId(p.placeId);
                          var location = response.result.geometry.location;
                          latLng = LatLng(location.lat, location.lng);
                          bloc.changeLocationString(
                              response.result.formattedAddress);
                          bloc.changeLocationLatLng(latLng);
                           sendRequest(response.result.formattedAddress,
                              response.result.reference);
                          destinationController.text =
                               response.result.formattedAddress;
                          initialPosition =
                               LatLng(location.lat, location.lng);
                          camPosition = CameraPosition(target: latLng);
                           _onCameraMove(camPosition);
                        })),
              ),
              new Positioned(
                bottom: 40.0,
                right: 20.0,
                child: new Container(
                  height: 40.0,
                  width: 40,
                  child: FloatingActionButton(
                    child: Icon(Icons.keyboard_arrow_right),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return MyHomePage(
                              latLng: latLng,
                              address: destinationController.text,
                              title: 'Title',
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
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
          markerId: MarkerId('markerid'),
          position: location,
          draggable: true,
          infoWindow: InfoWindow(title: address, snippet: adrAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(50.0)));
    });
  }

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

  void _setCurrentLocationMarker(LatLng initialPosition) async {
    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(
        initialPosition.latitude, initialPosition.longitude);
    _markers.add(Marker(
        markerId: MarkerId('markerid'),
        position: initialPosition,
        draggable: false,
        infoWindow: InfoWindow(
            title: placemark[0].name, snippet: placemark[0].subLocality),
        icon: BitmapDescriptor.defaultMarkerWithHue(50.0)));

    setState(() {
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
  }
}
