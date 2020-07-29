import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oye_taxi_v2/examples/load.dart';
import 'package:oye_taxi_v2/examples/place_marker.dart';
import 'package:oye_taxi_v2/screens/change_location.dart';
import 'package:oye_taxi_v2/screens/connect_and_overview.dart';
import '../requests/google_maps_requests.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:oye_taxi_v2/examples/location_provider.dart';


class MyHomePage extends StatefulWidget {
  LatLng latLng;
  String address;

  MyHomePage({this.latLng, this.address, Key key, this.title})
      : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(latLng, address);
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng latLng;
  String address;
  _MyHomePageState(this.latLng, this.address);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        body: Map(latLng, address));
  }
}

class Map extends StatefulWidget {
  LatLng latLng;
  String address;
  Map(this.latLng, this.address);
  @override
  _MapState createState() => _MapState(latLng, address);
}

class _MapState extends State<Map> {
  String address;

  LocationBloc bloc = LocationBloc();

  _MapState(this.latLng1, this.address);
  GoogleMapController mapController;

  LatLng latLng1, latLng2;
  int count;

  final _places = GoogleMapsPlaces(apiKey: apiKey);

  var _fromController = TextEditingController();

  var destinationController = TextEditingController();

  @override
  initState() {
    address = address != null ? _fromController.text = address : null;
    _getUserLocation();
  }

  @override
  void dispose() {
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final bloc = LocationProvider.of(context);

    return latLng1 == null
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
                    CameraPosition(target: latLng1, zoom: 16.0,tilt: 70.0),
                onMapCreated: onCreated,
                mapType: MapType.terrain,
                //   onCameraMove: _onCameraMove,
              ),
              new Container(
                decoration:
                    new BoxDecoration(color: Colors.white.withOpacity(0.8)),
              ),
              new Positioned(
                bottom: 40.0,
                left: 20.0,
                child: new Container(
                    height: 40.0,
                    width: 40,
                    child: InkWell(
                      highlightColor: Colors.black54,
                      child: Icon(Icons.local_taxi,color: Colors.black87,),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return DriverSide();
                            },
                          ),
                        );
                      },
                    )),
              ),
              new Positioned(
                top: 150.0,
                right: 15.0,
                left: 15.0,
                child: Card(
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _searchFieldFrom(context, bloc),
                    )),
              ),
              new Positioned(
                top: 220.0,
                right: 15.0,
                left: 15.0,
                child: Card(
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _searchFieldTo(context, bloc),
                    )),
              ),
              new Positioned(
                bottom: 40.0,
                right: 20.0,
                child: new Container(
                  height: 40.0,
                  width: 40,
                  child: Hero(
                    tag: "b",
                    child: FloatingActionButton(
                      backgroundColor: Colors.black54,
                      elevation: 0.0,
                      child: Icon(Icons.keyboard_arrow_right),
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return Connect(
                                  latLng1: latLng1,
                                  latLng2: latLng2,
                                  dest: destinationController.text);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _searchFieldFrom(BuildContext context, bloc) {
    return new TextField(
      cursorColor: Colors.black,
      focusNode: NoKeyboardEditableTextFocusNode(),
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
        hintText: "Your Location",
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
      ),
      controller: _fromController,
      onTap: () async {
     //  Navigator.push(
     //    context,
     //    MaterialPageRoute(
     //      builder: (context) {
     //        return Change_Location(latLng1);
     //      },
     //    ),
     //  );
      },
    );
  }

  Widget _searchFieldTo(BuildContext context, bloc) {
    return new TextField(
      cursorColor: Colors.black,
      controller: destinationController,
      textInputAction: TextInputAction.go,
      focusNode: NoKeyboardEditableTextFocusNode(),
      onTap: () async {
        destinationController.clear();
        Prediction p = await PlacesAutocomplete.show(
          context: context,
          apiKey: apiKey,
          mode: Mode.overlay,
          location: Location(latLng1.latitude, latLng1.longitude),
          language: "en",
          radius: 1000,
          //   components: [new Component(Component.postalCode, "en")]
        );

        PlacesDetailsResponse response =
            await _places.getDetailsByPlaceId(p.placeId);
        var location = response.result.geometry.location;
        setState(() {
          latLng2 = LatLng(location.lat, location.lng);
          bloc.changeLocationString(response.result.formattedAddress);
          bloc.changeLocationLatLng(latLng2);
          destinationController.text = response.result.formattedAddress;
        });

        bloc.changeLocationString(response.result.formattedAddress);
        bloc.changeLocationLatLng(latLng2);
        //  destinationController.text = response.result.formattedAddress;
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
        hintText: "Where to ?",
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
    Geolocator().getCurrentPosition().then((position) {
      setState(() {
        latLng1 = LatLng(position.latitude, position.longitude);
      });
    });
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(latLng1.latitude, latLng1.longitude);
    _fromController.text = placemark[0].name.toString();
    print(_fromController.text);
  }
}

class NoKeyboardEditableTextState extends EditableTextState {
  @override
  Widget build(BuildContext context) {
    Widget widget = super.build(context);
    return Container(
      decoration:
          UnderlineTabIndicator(borderSide: BorderSide(color: Colors.blueGrey)),
      child: widget,
    );
  }

  @override
  void requestKeyboard() {
    super.requestKeyboard();
    //hide keyboard
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}

class NoKeyboardEditableTextFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    // prevents keyboard from showing on first focus
    return false;
  }
}
