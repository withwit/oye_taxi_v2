import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oye_taxi_v2/examples/load.dart';

import 'package:oye_taxi_v2/examples/page.dart';
import 'package:oye_taxi_v2/ui/dialogue_info.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math';
import 'package:expandable_bottom_bar/expandable_bottom_bar.dart';

class PlaceMarkerPage extends Page {
  PlaceMarkerPage() : super(const Icon(Icons.place), 'Place marker');

  @override
  Widget build(BuildContext context) {
    return DefaultBottomBarController(
        dragLength: MediaQuery.of(context).size.height * 0.2,
        snap: true,
        child: const PlaceMarkerBody());
  }
}

class PlaceMarkerBody extends StatefulWidget {
  const PlaceMarkerBody();

  @override
  State<StatefulWidget> createState() => PlaceMarkerBodyState();
}

class PlaceMarkerBodyState extends State<PlaceMarkerBody> {
  LatLng latLng1;
  LatLng latLng_prev;
  LatLng latLng_final;

  MarkerId my_marker_id = MarkerId("me");

  Geolocator geolocator = Geolocator();

  var distanceInMeters;

  LocationOptions locationOptions =
  LocationOptions(accuracy: LocationAccuracy.high, timeInterval: 500);

  int mark_count = 0;

  Stream<List<DocumentSnapshot>> stream;

  Geoflutterfire geo;

  var radius = BehaviorSubject(seedValue: 1000.0);

  BitmapDescriptor myIcon, booked_ic, local1_ic, local2_ic, local3_ic, tip_p;

  double bearing = 2.0;

  double dist_bw;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  String rand_user_id = "unique_user_id";
  int cost = 20;
  double dest = 2.0;
  int num = 1;

  int is_new_pass = 0;

  PlaceMarkerBodyState();

  GoogleMapController controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    latLng_prev = latLng1;

    stream = radius.switchMap((rad) {
      var collectionReference = Firestore.instance.collection('live_locations');

      geo = Geoflutterfire();

      Position pos;
      Geolocator().getCurrentPosition().then((val) {
        pos = val;
      });
      GeoFirePoint center =
      geo.point(latitude: pos.latitude, longitude: pos.longitude);
      return geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: 100.0, field: 'location');
    });
    check_for_new_pass();
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(80, 80)), 'assets/taxi.png')
        .then((onValue) {
      myIcon = onValue;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(10, 10)), 'assets/onep.png')
        .then((onValue) {
      local1_ic = onValue;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(10, 10)), 'assets/twop.png')
        .then((onValue) {
      local2_ic = onValue;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(10, 10)), 'assets/threep.png')
        .then((onValue) {
      local3_ic = onValue;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(10, 10)), 'assets/one_tip.png')
        .then((onValue) {
      tip_p = onValue;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(10, 10)), 'assets/book.png')
        .then((onValue) {
      booked_ic = onValue;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  check_for_new_pass() {
    Firestore.instance
        .collection('live_locations')
        .where('requests1', isEqualTo: '_')
        .where('requests2', isEqualTo: '_')
        .snapshots()
        .listen((new_data) {
      setState(() {
        is_new_pass = 1;
        print("new pass $is_new_pass");
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      this.controller = controller;
      stream.listen((List<DocumentSnapshot> documentList) {
        _updateMarkers(documentList);
      });
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    //  markers.clear();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint point = document.data['location']['geopoint'];
      String type = document.data['type'];
      String from = document.data['from'];
      String to = document.data['to'];
      int cost = document.data['cost'];
      int num = document.data['num'];
      String user_id = document.documentID;
      Position pos =
      Position(latitude: point.latitude, longitude: point.longitude);
      _add(pos, MarkerId(mark_count.toString()), type, from, to, cost, num,
          user_id);
      mark_count++;
    });
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        if (markers.containsKey(selectedMarker)) {
          final Marker resetOld = markers[selectedMarker]
              .copyWith(iconParam: BitmapDescriptor.defaultMarker);
          markers[selectedMarker] = resetOld;
        }
        selectedMarker = markerId;
        final Marker newMarker = tappedMarker.copyWith(iconParam: myIcon);
        markers[markerId] = newMarker;
      });
    }
  }

  void _add(Position position, MarkerId id, String type, String from, String to,
      int cost, int num, String user_id) {
    setState(() {
      switch (type) {
        case 'me':
          final Marker marker = Marker(
            anchor: Offset(0.49, 0.5),
            rotation: 19.0,
            flat: false,
            markerId: id,
            zIndex: 0.0,
            position: LatLng(position.latitude, position.longitude),
            icon: myIcon,
            infoWindow: InfoWindow(title: type, snippet: "$num persons"),
            onTap: () {
              _onMarkerTapped(id);
            },
          );

          setState(() {
            markers[id] = marker;
          });
          break;
        case 'local':
          switch (num) {
            case 1:
              final Marker marker = Marker(
                markerId: MarkerId(mark_count.toString()),
                position: LatLng(position.latitude, position.longitude),
                icon: local1_ic,
                // infoWindow: InfoWindow(title: type, snippet: "$num persons"),
                onTap: () {
                  print("_____________");
                  showDialog(
                    context: context,
                    builder: (_) => Remove_Pass(
                        type: type,
                        from: from,
                        to: to,
                        cost: cost,
                        num: num,
                        user_id: user_id),
                  );

                  _onMarkerTapped(
                    MarkerId(mark_count.toString()),
                  );
                },
              );

              setState(() {
                markers[MarkerId(mark_count.toString())] = marker;
              });
              break;
            case 2:
              final Marker marker = Marker(
                markerId: MarkerId(mark_count.toString()),
                position: LatLng(position.latitude, position.longitude),
                icon: local2_ic,
                infoWindow: InfoWindow(title: type, snippet: "$num persons"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Remove_Pass(
                      type: type,
                      from: from,
                      to: to,
                      cost: cost,
                      num: num,
                    ),
                  );

                  _onMarkerTapped(
                    MarkerId(mark_count.toString()),
                  );
                },
              );

              setState(() {
                markers[MarkerId(mark_count.toString())] = marker;
              });
              break;
            default:
              final Marker marker = Marker(
                markerId: MarkerId(mark_count.toString()),
                position: LatLng(position.latitude, position.longitude),
                icon: local3_ic,
                infoWindow: InfoWindow(title: type, snippet: "$num persons"),
                onTap: () {
                  _onMarkerTapped(
                    MarkerId(mark_count.toString()),
                  );
                },
              );

              setState(() {
                markers[MarkerId(mark_count.toString())] = marker;
              });
              break;
          }
          break;
        case 'booked':
          final Marker marker = Marker(
            markerId: MarkerId(mark_count.toString()),
            position: LatLng(position.latitude, position.longitude),
            icon: booked_ic,
            infoWindow: InfoWindow(title: type, snippet: "$num persons"),
            onTap: () {
              _onMarkerTapped(
                MarkerId(mark_count.toString()),
              );
            },
          );

          setState(() {
            markers[MarkerId(mark_count.toString())] = marker;
          });
          break;
        default:
          print('It\'s weekend');
      }
    });
    print('updated marker');

    // final MarkerId markerId = my_marker_id;

    // final Marker marker = Marker(
    //   markerId: markerId,
    //   position: LatLng(
    //     position.latitude,
    //     position.longitude,
    //   ),
    //   infoWindow: InfoWindow(title: s, snippet: '*'),
    //   onTap: () {
    //     _onMarkerTapped(markerId);
    //   },
    // );

    // setState(() {
    //   markers[markerId] = marker;
    // });
  }

  void _remove(MarkerId id) {
    setState(() {
      if (markers.containsKey(id)) {
        markers.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
//    	a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
//    c = 2 ⋅ atan2( √a, √(1−a) )
//    d = R ⋅ c

    Size deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      //   floatingActionButton: GestureDetector(
      //       // Set onVerticalDrag event to drag handlers of controller for swipe effect
      //       onVerticalDragUpdate: DefaultBottomBarController.of(context).onDrag,
      //       onVerticalDragEnd: DefaultBottomBarController.of(context).onDragEnd,
      //       child: Hero(
      //           tag: "new_pass",
      //           child: RawChip(
      //             label: Icon(Icons.keyboard_arrow_up, color: Colors.white),
      //             backgroundColor: Colors.amber,
      //             onPressed: () {
      //               DefaultBottomBarController.of(context).swap();
      //             },
      //           ))),
      bottomNavigationBar: BottomExpandableAppBar(
        bottomAppBarColor: Colors.red,
        bottomOffset: 0.0,
        appBarHeight: 0.0,
        expandedHeight: MediaQuery.of(context).size.height * 0.2,
        shape: AutomaticNotchedShape(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        expandedBackColor: Colors.white24,
        expandedBody: GestureDetector(
          onVerticalDragUpdate: DefaultBottomBarController.of(context).onDrag,
          onVerticalDragEnd: DefaultBottomBarController.of(context).onDragEnd,
          child: Column(
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          "My Passengers",
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
              new Padding(
                padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                child: Divider(
                  height: 0.0,
                ),
              ),
              new Flexible(
                child: StreamBuilder<QuerySnapshot>(
                    stream: Firestore.instance
                        .collection('pass_list')
                        .document('current_list')
                        .collection('unique_driver_id')
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      // count of events
                      final int eventCount = snapshot.data.documents.length;
                      if (snapshot.hasError)
                        return new Text('Error: ${snapshot.error}');
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Center(child: CircularProgressIndicator());
                        default:
                          return new ListView.builder(
                              itemCount: eventCount,
                              itemBuilder: (context, index) {
                                var document = snapshot.data.documents;
                                return My_Pass_List(document, index, context);
                              });
                      }
                    }),
              ),
            ],
          ),
        ),
      ),
      endDrawer: Stack(
        children: <Widget>[
          Positioned(
            left: 80.0,
            bottom: 55.0,
            right: 5.0,
            child: Container(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: <Widget>[
                          new Container(
                            height: deviceSize.height * 0.5,
                            width: deviceSize.width * 0.963,
                            child: Column(
                              children: <Widget>[
                                new Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            "Passengers Ahead",
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
                                new Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30.0, right: 30.0),
                                  child: Divider(
                                    height: 0.0,
                                  ),
                                ),
                                SizedBox(
                                  height: 4.0,
                                ),
                                new Flexible(
                                  child: StreamBuilder<QuerySnapshot>(
                                      stream: Firestore.instance
                                          .collection('live_locations')
                                          .where("requests1", isEqualTo: "_")
                                          .where("requests2", isEqualTo: "_")
                                          .orderBy('distance',
                                          descending: false)
                                          .snapshots(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<QuerySnapshot>
                                          snapshot) {
                                        // count of events
                                        final int eventCount =
                                            snapshot.data.documents.length;
                                        if (snapshot.hasError)
                                          return new Text(
                                              'Error: ${snapshot.error}');
                                        switch (snapshot.connectionState) {
                                          case ConnectionState.waiting:
                                            return Center(
                                                child:
                                                CircularProgressIndicator());
                                          default:
                                            return new ListView.builder(
                                                itemCount: eventCount,
                                                itemBuilder: (context, index) {
                                                  final DocumentSnapshot
                                                  document = snapshot.data
                                                      .documents[index];
                                                  return New_Pass(
                                                      document, context);
                                                });
                                        }
                                      }),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0.0,
                            right: 5.0,
                            child: Container(
                              height: 45.0,
                              width: 45,
                              child: FloatingActionButton(
                                  heroTag: "new_pass",
                                  elevation: 0.0,
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 20.0,
                                  ),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: (latLng1 == null)
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
          //  GoogleMap(
          //    initialCameraPosition:
          //        CameraPosition(target: latLng1, zoom: 20.0),
          //    onMapCreated: onCreated,
          //    myLocationEnabled: true,
          //    mapType: MapType.normal,
          //    myLocationButtonEnabled: true,
          //    compassEnabled: true,
          //    markers: _markers,
          //    onCameraMove: _onCameraMove,
          //  ),
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
            CameraPosition(target: latLng1, zoom: 20.0),
            myLocationEnabled: true,
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            markers: Set<Marker>.of(markers.values),
          ),
          new Positioned(
            top: 40.0,
            right: 0.0,
            child: new Ripples(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
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
              bottom: 200.0,
              right: -10.0,
              child: InkWell(
                onTap: () {
                  _scaffoldKey.currentState.openEndDrawer();
                  setState(() {
                    is_new_pass = 0;
                  });
                },
                child: is_new_pass == 0
                    ? RawChip(
                  label:
                  Icon(Icons.chevron_left, color: Colors.white),
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    setState(() {});
                    _scaffoldKey.currentState.openEndDrawer();
                  },
                )
                    : Ripples(
                  child: Text(
                    "New !",
                    style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontSize: 14.0),
                  ),
                  size: 33.0,
                  color: Colors.red,
                ),
              )),

          new Positioned(
            right: 10.0,
            left: 10.0,
            bottom: 0.0,
            child: Stack(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      color: Colors.transparent,
                      height: deviceSize.height * 0.15,
                      width: deviceSize.width * 0.85,
                      child: StreamBuilder<QuerySnapshot>(
                          stream: Firestore.instance
                              .collection('pass_list')
                              .document('current_list')
                              .collection('unique_driver_id')
                              .orderBy('distance', descending: false)
                              .snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            // count of events
                            final int eventCount =
                                snapshot.data.documents.length;
                            if (snapshot.hasError)
                              return new Text('Error: ${snapshot.error}');
                            switch (snapshot.connectionState) {
                              case ConnectionState.waiting:
                                return Center(
                                    child: CircularProgressIndicator());
                              default:
                                return new ListView.builder(
                                    itemCount: eventCount,
                                    itemBuilder: (context, index) {
                                      var doc =
                                          snapshot.data.documents[0].data;

                                      String type =
                                      doc['type'].toString();
                                      String from =
                                      doc['from'].toString();
                                      String to = doc['to'].toString();
                                      int cost = doc['cost'];
                                      int num = doc['num'];
                                      double dist = doc['distance'];
                                      String user_id =
                                      doc['user_id'].toString();
                                      return Column(
                                        children: <Widget>[
                                          InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    Remove_Pass(
                                                        type: type,
                                                        from: from,
                                                        to: to,
                                                        cost: cost,
                                                        num: num,
                                                        user_id: user_id),
                                              );
                                            },
                                            child: Card(
                                                shape:
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(28.0),
                                                ),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .center,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                        const EdgeInsets
                                                            .only(
                                                            left:
                                                            4.0),
                                                        child:
                                                        CircleAvatar(
                                                          backgroundImage:
                                                          AssetImage(type ==
                                                              'local'
                                                              ? "assets/onep.png"
                                                              : "assets/book.png"),
                                                          backgroundColor:
                                                          Colors
                                                              .white,
                                                        ),
                                                      ),
                                                      Text(
                                                        to,
                                                        style: TextStyle(
                                                            fontWeight:
                                                            FontWeight
                                                                .w300,
                                                            fontSize:
                                                            25.0),
                                                      ),
                                                      SizedBox(
                                                        width: 30.0,
                                                      ),
                                                      Text(
                                                        "₹ $cost",
                                                        style: TextStyle(
                                                            fontWeight:
                                                            FontWeight
                                                                .w300,
                                                            fontSize:
                                                            25.0),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ),
                                        ],
                                      );
                                    });
                            }
                          }),
                    ),
                  ],
                ),
                Positioned(
                  top: 15.0,
                  right: 0.0,
                  child: GestureDetector(
                    // Set onVerticalDrag event to drag handlers of controller for swipe effect
                      onVerticalDragUpdate:
                      DefaultBottomBarController.of(context).onDrag,
                      onVerticalDragEnd:
                      DefaultBottomBarController.of(context)
                          .onDragEnd,
                      child: Hero(
                          tag: "new_pass",
                          child: RawChip(
                            label: Icon(Icons.keyboard_arrow_up,
                                color: Colors.white),
                            backgroundColor: Colors.amber,
                            onPressed: () {
                              DefaultBottomBarController.of(context)
                                  .swap();
                            },
                          ))),
                ),
              ],
            ),
          ),

          new Positioned(
            bottom: 10.0,
            left: 20.0,
            child: new Container(
              height: 40.0,
              width: 40,
              child: FloatingActionButton(
                elevation: 0.0,
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.add,
                  size: 20.0,
                ),
                onPressed: () async {
                  Firestore.instance
                      .collection('live_locations')
                      .document(rand_user_id)
                      .setData({
                    'requests1': "_",
                    'requests2': "_",
                    'location': GeoPoint(23.168839 - num * 0.00001,
                        79.93353400000009 + num * 0.0001),
                    'user_id': rand_user_id,
                    'cost': cost,
                    'distance': 3.2,
                    'from': "Ekta Chowk ",
                    'to': "ITI college",
                    'num': num,
                    'type': 'local',
                  });
                  rand_user_id = rand_user_id + "uu";
                  cost++;
                  num++;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latLng1 = LatLng(position.latitude, position.longitude);
      latLng_prev = latLng1;
    });

    geolocator.getPositionStream(locationOptions).listen((Position position) {
      Geolocator()
          .distanceBetween(latLng_prev.latitude, latLng_prev.longitude,
          position.latitude, position.longitude)
          .then((d) {
        dist_bw = d;
      });
      if (dist_bw > 5.0) {
        _remove(my_marker_id);
        _add(position, my_marker_id, "me", "", "", 0, 0, "");
        print(LatLng(latLng_prev.latitude, latLng_prev.longitude).toString());
        print(LatLng(position.latitude, position.longitude).toString());
        double deg = _calculate(
          LatLng(latLng_prev.latitude, latLng_prev.longitude),
          LatLng(position.latitude, position.longitude),
        );
        CameraPosition camp = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            bearing: deg,
            zoom: 20.0,
            tilt: 70.0);
        controller.animateCamera(
          CameraUpdate.newCameraPosition(camp),
        );
        latLng_prev = LatLng(position.latitude, position.longitude);
        print(my_marker_id.value.toString());
        print('updated');
      }
    });
  }

  double _calculate(LatLng prev, LatLng fin) {
    double del_lat, del_lon, lat1, lat2, lon1, lon2;
    lat1 = prev.latitude;
    lat2 = fin.latitude;
    del_lat = lat2 - lat1;
    lon1 = prev.longitude;
    lon2 = fin.longitude;
    del_lon = lon2 - lon1;

//  var a = sin(del_lat/2)* sin(del_lat/2) + cos(lat1) * cos(lat2) * ( sin(del_lon)/2*sin(del_lon/2) );

    // θ = atan2( sin Δλ ⋅ cos φ2    ,              cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
    var a = atan2(sin(del_lon / 2) * cos(del_lat / 2),
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(del_lon));
    var deg = (180 / pi) * a;
    print("OOOOOOOOOOOOOOOOOOOOOOOOOO");
    print(deg);
    print("OOOOOOOOOOOOOOOOOOOOOOOOOO");

    return deg;
  }

  Get_My_First_Data() {
    Size deviceSize = MediaQuery.of(context).size;

    new Flexible(
      child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('pass_list')
              .document('current_list')
              .collection('unique_driver_id')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            // count of events
            final int eventCount = snapshot.data.documents.length;
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              default:
                return new ListView.builder(
                    itemCount: eventCount,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data.documents[0];

                      String type = doc['type'].toString();
                      String from = doc['from'].toString();
                      String to = doc['to'].toString();
                      int cost = doc['cost'];
                      int num = doc['num'];
                      double dist = doc['distance'];
                      String user_id = doc['user_id'].toString();
                      return Column(
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Remove_Pass(
                                    type: type,
                                    from: from,
                                    to: to,
                                    cost: cost,
                                    num: num,
                                    user_id: user_id),
                              );
                            },
                            child: Container(
                              height: deviceSize.height * 0.10,
                              width: deviceSize.width * 0.9,
                              child: Card(
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0),
                                        child: CircleAvatar(
                                          backgroundImage: AssetImage(
                                              type == 'local'
                                                  ? "assets/onep.png"
                                                  : "assets/book.png"),
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        to,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 25.0),
                                      ),
                                      SizedBox(
                                        width: 30.0,
                                      ),
                                      Text(
                                        "₹ $cost",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 25.0),
                                      ),
                                    ],
                                  )),
                            ),
                          ),
                        ],
                      );
                    });
            }
          }),
    );
  }

/*
  Future<void> _changeInfoAnchor() async {
    final Marker marker = markers[selectedMarker];
    final Offset currentAnchor = marker.infoWindow.anchor;
    final Offset newAnchor = Offset(1.0 - currentAnchor.dy, currentAnchor.dx);
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        infoWindowParam: marker.infoWindow.copyWith(
          anchorParam: newAnchor,
        ),
      );
    });
  }


  void _changePosition() {
    final Marker marker = markers[selectedMarker];
    final LatLng current = marker.position;
    final Offset offset = Offset(
      center.latitude - current.latitude,
      center.longitude - current.longitude,
    );
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        positionParam: LatLng(
          center.latitude + offset.dy,
          center.longitude + offset.dx,
        ),
      );
    });
  }

  void _changeAnchor() {
    final Marker marker = markers[selectedMarker];
    final Offset currentAnchor = marker.anchor;
    final Offset newAnchor = Offset(1.0 - currentAnchor.dy, currentAnchor.dx);
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        anchorParam: newAnchor,
      );
    });
  }

  Future<void> _toggleDraggable() async {
    final Marker marker = markers[selectedMarker];
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        draggableParam: !marker.draggable,
      );
    });
  }

  Future<void> _toggleFlat() async {
    final Marker marker = markers[selectedMarker];
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        flatParam: !marker.flat,
      );
    });
  }

  Future<void> _changeInfo() async {
    final Marker marker = markers[selectedMarker];
    final String newSnippet = marker.infoWindow.snippet + '*';
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        infoWindowParam: marker.infoWindow.copyWith(
          snippetParam: newSnippet,
        ),
      );
    });
  }

  Future<void> _changeAlpha() async {
    final Marker marker = markers[selectedMarker];
    final double current = marker.alpha;
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        alphaParam: current < 0.1 ? 1.0 : current * 0.75,
      );
    });
  }

  Future<void> _changeRotation() async {
    final Marker marker = markers[selectedMarker];
    final double current = marker.rotation;
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        rotationParam: current == 330.0 ? 0.0 : current + 30.0,
      );
    });
  }

  Future<void> _toggleVisible() async {
    final Marker marker = markers[selectedMarker];
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        visibleParam: !marker.visible,
      );
    });
  }

  Future<void> _changeZIndex() async {
    final Marker marker = markers[selectedMarker];
    final double current = marker.zIndex;
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        zIndexParam: current == 12.0 ? 0.0 : current + 1.0,
      );
    });
  }

  void _setMarkerIcon(BitmapDescriptor assetIcon) {
    if (selectedMarker == null) {
      return;
    }

    final Marker marker = markers[selectedMarker];
    setState(() {
      markers[selectedMarker] = marker.copyWith(
        iconParam: assetIcon,
      );
    });
  }

  _getAssetIcon(BuildContext context) {
    final Completer<BitmapDescriptor> bitmapIcon =
        Completer<BitmapDescriptor>();
    final ImageConfiguration config = createLocalImageConfiguration(context);

    const AssetImage('assets/taxi.png')
        .resolve(config)
        .addListener((ImageInfo image, bool sync) async {
      final ByteData bytes =
          await image.image.toByteData(format: ImageByteFormat.png);
      final BitmapDescriptor bitmap =
          BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      bitmapIcon.complete(bitmap);
    });

    return bitmapIcon.future;
  }
*/
}

New_Pass(DocumentSnapshot document, BuildContext context) {
  var doc = document.data;
  Size deviceSize = MediaQuery.of(context).size;

  String type = doc['type'];
  String from = doc['from'];
  String to = doc['to'];
  int cost = doc['cost'];
  int num = doc['num'];
  int req = doc['requests1'] == "_" ? 1 : 2;
  String user_id = doc['user_id'];
  GeoPoint user_loc = doc['location'];
  double dist = doc['distance'];

  Get_dist_bw(user_loc).asStream().listen((val) async {
    Firestore.instance
        .collection('live_locations')
        .document(user_id)
        .updateData({
      'distance': val,
    });
  });

  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[
      InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Collect_Pass(
                req: req,
                type: doc['type'],
                from: doc['from'],
                to: doc['to'],
                dist: doc['distance'],
                cost: doc['cost'],
                num: doc['num'],
                user_id: doc['user_id']),
          );
        },
        child: Container(

          child: Card(
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius
                    .circular(28.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(type == 'local'
                              ? "assets/onep.png"
                              : "assets/book.png"),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: deviceSize.width * 0.28,
                              child: Card(
                                elevation: 0.0,
                                clipBehavior: Clip.antiAlias,
                                child: Text(
                                  to,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w300, fontSize: 25.0),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "(${dist.toStringAsPrecision(2)} km)",
                              style: TextStyle(
                                  fontWeight: FontWeight.w300, fontSize: 25.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            "₹",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 22.0,
                                color: Colors.green),
                          ),
                          Text(
                            " $cost",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w200,
                                fontSize: 36.0,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )),
        ),
      ),
    ],
  );
}

Position my_loc;

Future Get_dist_bw(GeoPoint user_loc) async {
  Geolocator().getCurrentPosition().asStream().listen((pos) {
    my_loc = pos;
  });

  double d = await Geolocator().distanceBetween(my_loc.latitude,
      my_loc.longitude, user_loc.latitude, user_loc.longitude) /
      1000;
  double rate = 2.5;
  double price_max = (d * (rate + 1.5));
  double price_min = (d * (rate));
  String distanceInKm = d.toStringAsFixed(2);

  print(distanceInKm);
  print(price_min);
  print(price_max);
  return d;
}

Widget My_Pass_List(
    List<DocumentSnapshot> document,
    int index,
    BuildContext context,
    ) {
  Size deviceSize = MediaQuery.of(context).size;
  var doc = document[index].data;
  String type = doc['type'];
  String from = doc['from'];
  String to = doc['to'];
  int cost = doc['cost'];
  int num = doc['num'];
  double dist = doc['distance'];
  String user_id = doc['user_id'];
  return Column(
    children: <Widget>[
      InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Remove_Pass(
                type: type,
                from: from,
                to: to,
                cost: cost,
                num: num,
                user_id: user_id),
          );
        },
        child: Container(
          height: deviceSize.height * 0.08,
          width: deviceSize.width * 0.9,
          child: Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(
                          type == 'local' ? "assets/onep.png" : "assets/book.png"),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Text(
                    to,
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  Text(
                    "($dist)",
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  SizedBox(
                    width: 30.0,
                  ),
                  Text(
                    "₹ $cost",
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                ],
              )),
        ),
      ),
    ],
  );
}
