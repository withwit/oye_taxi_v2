import 'dart:async';
import 'dart:math';
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
import 'package:expandable_bottom_bar/expandable_bottom_bar.dart';

class Overview extends Page {
  LatLng latLng1;
  String dest;

  Overview({this.latLng1, this.dest})
      : super(const Icon(Icons.place), 'Place marker');

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

  int mark_count = 1;

  Geoflutterfire geo;

  var radius = BehaviorSubject(seedValue: 1.0);

  BitmapDescriptor myIcon, booked_ic, local1_ic, local2_ic, local3_ic, tip_p;

  double bearing = 2.0;

  double dist_bw;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  String rand_taxi_id = "unique_taxi_id";
  int cost = 20;
  double dest = 2.0;
  int num = 1;

  int is_new_pass = 0;

  GeoFirePoint center;

  Observable<List<DocumentSnapshot>> stream2;

  Stream<QuerySnapshot> stream;

  PlaceMarkerBodyState();

  GoogleMapController controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    //_taxi_prediction();

    geo = Geoflutterfire();

    Geolocator().getCurrentPosition().then((pos) {
      latLng1 = LatLng(pos.latitude, pos.longitude);
    });

    stream = Firestore.instance.collection('live_taxi_loc').snapshots();

    latLng_prev = latLng1;

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
      stream.listen((data) {
        _updateMarkers(data.documents);
      });
    });
  }

  void _update_nearest_taxi(List<DocumentSnapshot> documentList) {
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint point = document.data['location']['geopoint'];
      String type = document.data['type'];
      String from = document.data['from'];
      String to = document.data['to'];
      int cost = document.data['cost'];
      int num = document.data['num'];
      String driver_id = document.documentID;
      print("yyyyyyyyyyyyyyy $to");
      String saved_tx_id;
      GeoPoint saved_tx_loc;
      double saved_tx_dist;
      Firestore.instance.collection("live_user_loc").snapshots().listen((dat) {
        dat.documents.forEach((f) {
          saved_tx_id = f.data['first_driver_id'];
          saved_tx_loc = f.data['first_driver_loc'];
          saved_tx_dist = f.data['first_driver_dist'];
        });
      });

      Get_dist_bw(saved_tx_loc).asStream().listen((dist) {
        saved_tx_dist = dist;
      });

      Get_dist_bw(point).asStream().listen((val_current) {
        print(
            "curr nearest distnace of ${to}   vvvvvvvvvvvvvvvvvvvvvvvv : ${val_current}    and this saved : $saved_tx_dist");
        if (val_current < saved_tx_dist) {
          Firestore.instance
              .collection('live_user_loc')
              .document('unique_user_id')
              .updateData({
            'first_driver_id': driver_id,
            'first_driver_loc': point,
            'first_driver_dist': val_current,
          });
        } else {
          print("NOOOOOOOOOOO");
        }
      });

      //  Get_dist_bw(point).asStream().listen((val_current)  {
      //    Get_dist_bw(current_svd_driver_loc)
      //        .asStream()
      //        .listen((val_saved)  {
      //          print("saved val vvvvvvvvvvvvvvvvvvvvvvvv : ${val_saved}");
      //          print("curr val vvvvvvvvvvvvvvvvvvvvvvvv : ${val_current}");
      //       Firestore.instance
      //          .collection('live_user_loc')
      //          .document('unique_user_iduuuu')
      //          .updateData({
      //        'first_driver_id':
      //            val_current > val_saved ? driver_id : svd_driver_id,
      //        'first_driver_loc':
      //            val_current > val_saved ? point : current_svd_driver_loc,
      //      });
      //    });
      //  });
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint point = document.data['location']['geopoint'];
      String type = document.data['type'];
      String from = document.data['from'];
      String to = document.data['to'];
      int cost = document.data['cost'];
      int num = document.data['num'];
      String driver_id = document.documentID;
      print("XXXX $to");
      Position pos =
          Position(latitude: point.latitude, longitude: point.longitude);
      _add(pos, MarkerId(mark_count.toString()), type, from, to, cost, num,
          driver_id);
      mark_count++;
      GeoPoint current_svd_driver_loc;
      String svd_driver_id = "__";
      Firestore.instance
          .collection('live_user_loc')
          .document('unique_user_iduuuu')
          .snapshots()
          .listen((data) {
        current_svd_driver_loc = data.data['first_driver_loc'];
        svd_driver_id = data.data['first_driver_id'];
      });

      Get_dist_bw(point).asStream().listen((val_current) {
        print("curr val vvvvvvvvvvvvvvvvvvvvvvvv : ${val_current}");
        Firestore.instance
            .collection('live_user_loc')
            .document('unique_user_iduuuu')
            .updateData({
          'first_driver_id': driver_id,
          'first_driver_loc': point,
        });
      });

      //  Get_dist_bw(point).asStream().listen((val_current)  {
      //    Get_dist_bw(current_svd_driver_loc)
      //        .asStream()
      //        .listen((val_saved)  {
      //          print("saved val vvvvvvvvvvvvvvvvvvvvvvvv : ${val_saved}");
      //          print("curr val vvvvvvvvvvvvvvvvvvvvvvvv : ${val_current}");
      //       Firestore.instance
      //          .collection('live_user_loc')
      //          .document('unique_user_iduuuu')
      //          .updateData({
      //        'first_driver_id':
      //            val_current > val_saved ? driver_id : svd_driver_id,
      //        'first_driver_loc':
      //            val_current > val_saved ? point : current_svd_driver_loc,
      //      });
      //    });
      //  });
    });
    mark_count++;
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        if (markers.containsKey(selectedMarker)) {
          final Marker resetOld =
              markers[selectedMarker].copyWith(iconParam: myIcon);
          markers[selectedMarker] = resetOld;
        }
        selectedMarker = markerId;
        final Marker newMarker =
            tappedMarker.copyWith(iconParam: BitmapDescriptor.defaultMarker);
        markers[markerId] = newMarker;
      });
    }
  }

  void _add(Position position, MarkerId id, String type, String from, String to,
      int cost, int num, String user_id) {
    //  pos, MarkerId(mark_count.toString()), type, from, to, cost, num,
    //          user_id

    print("marker count $mark_count");
    print("type $type");
    print("pos ${position.latitude}");
    setState(() {
      switch (type) {
        case 'me':
          final Marker marker = Marker(
            anchor: Offset(0.49, 0.5),
            rotation: 0.0,
            flat: false,
            markerId: id,
            zIndex: 0.0,
            position: LatLng(position.latitude, position.longitude),
            icon: local1_ic,
            infoWindow: InfoWindow(title: type, snippet: "$num persons"),
            onTap: () {
              // _onMarkerTapped(id);
            },
          );

          setState(() {
            markers[id] = marker;
          });
          break;
        default:
          final Marker marker = Marker(
            anchor: Offset(0.49, 0.5),
            rotation: 0.0,
            flat: false,
            markerId: id,
            zIndex: 0.0,
            position: LatLng(position.latitude, position.longitude),
            icon: myIcon,
            infoWindow: InfoWindow(title: type, snippet: "$num persons"),
            onTap: () {
              //   _onMarkerTapped(id);
            },
          );

          setState(() {
            markers[id] = marker;
          });
          break;
      }
    });
    print('updated marker');
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
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      /*
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
      */
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
                                            "Accepted Requests",
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
                                //  new Flexible(
                                //    child: StreamBuilder<QuerySnapshot>(
                                //        stream: Firestore.instance
                                //            .collection('live_user_loc')
                                //            .where("requests1", isEqualTo: "_")
                                //            .where("requests2", isEqualTo: "_")
                                //            .orderBy('distance',
                                //                descending: false)
                                //            .snapshots(),
                                //        builder: (BuildContext context,
                                //            AsyncSnapshot<QuerySnapshot>
                                //                snapshot) {
                                //          // count of events
                                //          final int eventCount =
                                //              snapshot.data.documents.length;
                                //          if (snapshot.hasError)
                                //            return new Text(
                                //                'Error: ${snapshot.error}');
                                //          switch (snapshot.connectionState) {
                                //            case ConnectionState.waiting:
                                //              return Center(
                                //                  child:
                                //                      CircularProgressIndicator());
                                //            default:
                                //              return new ListView.builder(
                                //                  itemCount: eventCount,
                                //                  itemBuilder: (context, index) {
                                //                    final DocumentSnapshot
                                //                        document = snapshot.data
                                //                            .documents[index];
                                //                    return Nearest_taxi(
                                //                        document, context);
                                //                  });
                                //          }
                                //        }),
                                //  ),
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
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
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
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition:
                      CameraPosition(target: latLng1, zoom: 12.0),
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
                /*
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
                */
                new Positioned(
                  bottom: 10.0,
                  left: 20.0,
                  child: new Container(
                    height: 40.0,
                    width: 40,
                    child: FloatingActionButton(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.add,
                        size: 20.0,
                      ),
                      onPressed: () async {
                        Position position = await Geolocator()
                            .getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high);
                        setState(() {
                          latLng1 =
                              LatLng(position.latitude, position.longitude);
                          GeoFirePoint geoFirePoint = geo.point(
                              latitude: latLng1.latitude,
                              longitude: latLng1.longitude);

                          Firestore.instance
                              .collection('live_taxi_loc')
                              .document(rand_taxi_id)
                              .setData({
                            'location': geoFirePoint.data,
                            'user_id': rand_taxi_id,
                            'num': num,
                            'type': 'local',
                          });
                          print("current loc: $latLng1");
                        });

                        rand_taxi_id = rand_taxi_id + "d";
                        cost++;
                        num++;

                        //   Firestore.instance.collection('live_locations').add({
                        //     'type': 'local',
                        //     'from': 'G',
                        //     'to': 'Ekta Chowk',
                        //     'cost': 45,
                        //     'num': 2,
                        //     'name': 'random name',
                        //     'location': geoFirePoint.data
                        //   }).then((_) {
                        //     print('added ${geoFirePoint.hash} successfully');
                        //   });
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future _taxi_prediction() async {
    //////////PREDICTION SPACE??????????????

    stream2 = radius.switchMap((rad) {
      var collectionReference = Firestore.instance.collection('live_taxi_loc');

      return geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: 1.0, field: 'location');
    });

    stream2.listen((List<DocumentSnapshot> documentList) {
      print("listening from getLoc()");
      _update_nearest_taxi(documentList);
    }).asFuture();

    // Future.delayed(const Duration(seconds: 5), ()  {
    //     stream2.listen((List<DocumentSnapshot> documentList) {
    //     if (dist_bw > 0.0) {
    //       print("listening from getLoc()");
    //       _update_nearest_taxi(documentList);
    //     }
    //   }).asFuture();
    // });

////////////////////////////
  }

  Future _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latLng1 = LatLng(position.latitude, position.longitude);
      print("current loc: $latLng1");
      latLng_prev = latLng1;
    });

    center =
        geo.point(latitude: latLng1.latitude, longitude: latLng1.longitude);

    geolocator.getPositionStream(locationOptions).listen((Position position) {
      Geolocator()
          .distanceBetween(latLng_prev.latitude, latLng_prev.longitude,
              position.latitude, position.longitude)
          .then((d) {
        dist_bw = d;
      });

      //////////PREDICTION SPACE??????????????

      stream2 = radius.switchMap((rad) {
        var collectionReference =
            Firestore.instance.collection('live_taxi_loc');

        return geo
            .collection(collectionRef: collectionReference)
            .within(center: center, radius: 1.0, field: 'location');
      });

      stream2.listen((List<DocumentSnapshot> documentList) {
        print("listening from getLoc()");
        // _update_nearest_taxi(documentList);
      }).asFuture();

      // Future.delayed(const Duration(seconds: 5), ()  {
      //     stream2.listen((List<DocumentSnapshot> documentList) {
      //     if (dist_bw > 0.0) {
      //       print("listening from getLoc()");
      //       _update_nearest_taxi(documentList);
      //     }
      //   }).asFuture();
      // });

////////////////////////////

      if (dist_bw > 0.0) {
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
            zoom: 17.0,
            tilt: 80.0);
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

  Nearest_taxi(DocumentSnapshot document, BuildContext context) {
    var doc = document.data;
    Size deviceSize = MediaQuery.of(context).size;

    String type = doc['type'];
    String from = doc['from'];
    String to = doc['to'];
    int cost = doc['cost'];
    int num = doc['num'];
    int req = doc['requests1'] == "_" ? 1 : 2;
    String user_id = doc['user_id'];
    GeoPoint user_loc = doc['location']['geopoint'];
    double dist = doc['distance'];

    Get_dist_bw(user_loc).asStream().listen((val) async {
      await Firestore.instance
          .collection('live_taxi_loc')
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
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
                                        fontWeight: FontWeight.w300,
                                        fontSize: 25.0),
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
                                    fontWeight: FontWeight.w300,
                                    fontSize: 25.0),
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

  @override
  void dispose() {
stream.listen((h){}).cancel();
stream2.listen((g){}).cancel();
super.dispose();
  }
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
