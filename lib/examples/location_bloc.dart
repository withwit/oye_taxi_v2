import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

class LocationBloc {
  final BehaviorSubject<String> _locationString = BehaviorSubject();
  final BehaviorSubject<LatLng> _locationLatLng = BehaviorSubject();

  Stream<String> get locationString => _locationString.stream;

  Stream<LatLng> get locationLatLng => _locationLatLng.stream;

  // Change fields

  Function(String) get changeLocationString => _locationString.sink.add;

  Function(LatLng) get changeLocationLatLng => _locationLatLng.sink.add;

  dispose() {
    _locationString.close();
    _locationLatLng.close();
  }
}
