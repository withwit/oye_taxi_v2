import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Collect_Pass extends StatefulWidget {
  String type, from, to, user_id;
  int cost, num, req;
  double dist;
  Collect_Pass(
      {this.req,
      this.type,
      this.from,
      this.to,
      this.dist,
      this.cost,
      this.num,
      this.user_id});

  @override
  State<StatefulWidget> createState() =>
      Collect_PassState(req, type, from, to, dist, cost, num, user_id);
}

class Collect_PassState extends State<Collect_Pass>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> scaleAnimation;

  String type, from, to, user_id;
  int cost, num;
  double dist;

  int req;

  CollectionReference stream;
  CollectionReference my_pass_stream;

  Collect_PassState(this.req, this.type, this.from, this.to, this.dist,
      this.cost, this.num, this.user_id);

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.easeIn);

    controller.addListener(() {
      setState(() {});
    });
    print("++++++++++++++++++");
    print(type.toString());
    print(from.toString());
    print(to.toString());
    print(cost.toString());
    print(num.toString());
    print("++++++++++++++++++");

    controller.forward();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    stream = Firestore.instance.collection('live_user_loc');

    my_pass_stream = Firestore.instance
        .collection('pass_list')
        .document('current_list')
        .collection('unique_driver_id');

    var deviceSize = MediaQuery.of(context).size;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            height: deviceSize.height * 0.31,
            width: deviceSize.width * 0.78,
            decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0))),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: <Widget>[
                  Text(
                    from,
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  Text("|"),
                  Text("|"),
                  Text("V"),
                  Text(
                    to,
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Text("_________________________"),
                  Text(
                    "₹ $cost",
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  Text("_________________________"),
                  SizedBox(
                    height: 10.0,
                  ),
                  InkWell(
                      child: RawChip(
                    label: Text("Collect",
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            fontSize: 22.0)),
                    backgroundColor: Colors.amber,
                    onPressed: () {
                      Firestore.instance
                          .collection('pass_list')
                          .document('current_list')
                          .collection('unique_driver_id')
                          .document(user_id)
                          .setData({
                        'user_id': user_id,
                        'cost': cost,
                        'distance': dist,
                        'dis_from_me': dist,
                        'from': from,
                        'to': to,
                        'num': num,
                        'type': type,
                      }).then((_) async {
                       await Firestore.instance
                            .collection('live_user_loc')
                            .document(user_id)
                            .updateData({
                          'requests$req': 'unique_driver_id',
                        }).then((_) {
                          Navigator.of(context).pop();
                        });
                      });
                    },
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Remove_Pass extends StatefulWidget {
  String type, from, to, user_id;
  int cost, num;
  Remove_Pass(
      {this.type, this.from, this.to, this.cost, this.num, this.user_id});

  @override
  State<StatefulWidget> createState() =>
      Remove_PassState(type, from, to, cost, num, user_id);
}

class Remove_PassState extends State<Remove_Pass>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> scaleAnimation;

  String type, from, to, user_id;
  int cost, num;

  int req = 0;

  CollectionReference stream;
  CollectionReference my_pass_stream;

  Remove_PassState(
      this.type, this.from, this.to, this.cost, this.num, this.user_id);

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.easeIn);

    controller.addListener(() {
      setState(() {});
    });
    print("++++++++++++++++++");
    print(type.toString());
    print(from.toString());
    print(to.toString());
    print(cost.toString());
    print(num.toString());
    print("++++++++++++++++++");

    controller.forward();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    stream = Firestore.instance
        .collection('pass_list')
        .document('current_list')
        .collection('unique_driver_id');
    stream.document(user_id).snapshots().listen((num_req) {
      req = num_req['requests'];
    });

    my_pass_stream = Firestore.instance
        .collection('pass_list')
        .document('current_list')
        .collection('unique_driver_id');

    var deviceSize = MediaQuery.of(context).size;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            height: deviceSize.height * 0.31,
            width: deviceSize.width * 0.78,
            decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0))),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: <Widget>[
                  Text(
                    from,
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  Text("|"),
                  Text("|"),
                  Text("V"),
                  Text(
                    to,
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Text("_________________________"),
                  Text(
                    "₹ $cost",
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 25.0),
                  ),
                  Text("_________________________"),
                  SizedBox(
                    height: 10.0,
                  ),
                  InkWell(
                      child: RawChip(
                    label: Text("Completed",
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            fontSize: 22.0)),
                    backgroundColor: Colors.lightGreen,
                    onPressed: () {
                      Firestore.instance
                          .collection('pass_list')
                          .document('current_list')
                          .collection('unique_driver_id')
                          .document(user_id)
                          .delete();

                      //  Firestore.instance
                      //      .collection('live_locations')
                      //      .document(user_id)
                      //      .delete();
                      print("completed");
                      Navigator.of(context).pop();
                    },
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
