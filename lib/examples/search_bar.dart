import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:oye_taxi_v2/examples/location_provider.dart';

const String apiKey = 'AIzaSyAg6qVpxp7iJbWhdBL9FYRxhscg7Yv87HY';

class LocationPage extends StatelessWidget {
  final _places = GoogleMapsPlaces(apiKey: apiKey);

  @override
  Widget build(BuildContext context) {
    final bloc = LocationProvider.of(context) == null
        ? "asaas"
        : LocationProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 10)),
            Text('Select your location:', textAlign: TextAlign.center),
            _searchField(context, bloc),
            Padding(padding: EdgeInsets.only(top: 10)),
            _buildLocation(bloc),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context, LocationBloc bloc) {
    return new StreamBuilder(
      stream: bloc.locationString,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        var _controller = TextEditingController();
        _controller.text = snapshot.data;
        return TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: "Search"),
          onTap: () async {
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
            bloc.changeLocationString(response.result.formattedAddress);
            bloc.changeLocationLatLng(latLng);
          },
        );
      },
    );
  }

  Widget _buildLocation(LocationBloc bloc) {
    return StreamBuilder(
      stream: bloc.locationLatLng,
      builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 80,
                  child: Text('latitude: '),
                ),
                Text('${snapshot.hasData ? snapshot.data.latitude : ''}')
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 80,
                  child: Text('longitude: '),
                ),
                Text('${snapshot.hasData ? snapshot.data.longitude : ''}')
              ],
            )
          ],
        );
      },
    );
  }
}
