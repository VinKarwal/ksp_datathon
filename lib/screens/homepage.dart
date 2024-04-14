import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as ws;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _getPolylines();
    _getMarkers();
  }

  // void _getMarkers() async {
  //   var dbRef = FirebaseDatabase.instance.ref().child('markers');
  //   var event = await dbRef.once();
  //   var snapshot = event.snapshot;

  //   setState(() {
  //     _markers.clear();
  //     _circles.clear();
  //     if (snapshot.value != null) {
  //       var latitudes = List<double>.from(snapshot.value['lat'].values);
  //       var longitudes = List<double>.from(snapshot.value['long'].values);
  //       var visibilities = List<bool>.from(snapshot.value['visibility'].values);

  //       for (var i = 0; i < latitudes.length; i++) {
  //         if (visibilities[i]) {
  //           var point = LatLng(latitudes[i], longitudes[i]);
  //           var marker = Marker(
  //             markerId: MarkerId('marker$i'),
  //             position: point,
  //           );

  //           _markers.add(marker);

  //           var closeMarkers = _markers.where((m) {
  //             return _calculateDistance(m.position, point) < 0.1; // 100 meters
  //           }).toList();

  //           if (closeMarkers.length >= 3) {
  //             var circle = Circle(
  //               circleId: CircleId('circle${_circles.length}'),
  //               center: point,
  //               radius: 100,
  //               fillColor: Colors.red.withOpacity(0.5),
  //               strokeColor: Colors.red,
  //               strokeWidth: 1,
  //             );

  //             _circles.add(circle);
  //           }
  //         }
  //       }
  //     }
  //   });
  // }

  void _getMarkers() async {
    var dbRef = FirebaseDatabase.instance.ref().child('vehicles');
    var event = await dbRef.once();
    var snapshot = event.snapshot;

    setState(() {
      _markers.clear();
      _circles.clear();
      if (snapshot.value is Map) {
        // var latitudes = List<double>.from(
        //     (snapshot.value as Map<String, dynamic>)['lat'].values);
        // var longitudes = List<double>.from(
        //     (snapshot.value as Map<String, dynamic>)['long'].values);
        var data = Map<String, dynamic>.from(snapshot.value as Map);
        var latitudes = List<double>.from(data['lat']);
        var longitudes = List<double>.from(data['long']);
        for (var i = 0; i < latitudes.length; i++) {
          var point = LatLng(latitudes[i], longitudes[i]);
          var marker = Marker(
            markerId: MarkerId('marker$i'),
            position: point,
          );

          print('Adding marker at $point'); // Debugging line

          _markers.add(marker);

          var closeMarkers = _markers.where((m) {
            return _calculateDistance(m.position, point) < 0.1; // 100 meters
          }).toList();

          if (closeMarkers.length >= 3) {
            var circle = Circle(
              circleId: CircleId('circle${_circles.length}'),
              center: point,
              radius: 50,
              fillColor: Colors.red.withOpacity(0.5),
              strokeColor: Colors.red,
              strokeWidth: 1,
            );

            _circles.add(circle);
          }
        }
      } else {
        print('No data found'); // Debugging line
      }
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) *
            c(point2.latitude * p) *
            (1 - c((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  void _getPolylines() async {
    var dbRef = FirebaseDatabase.instance.ref().child('polylines');
    var event = await dbRef.once();
    var snapshot = event.snapshot;

    setState(() {
      _polylines.clear();
      if (snapshot.value != null) {
        List<dynamic> polylineData = snapshot.value as List<dynamic>;
        polylineData.asMap().forEach((index, value) {
          var latitudes = List<double>.from(value['lat'].map((lat) => lat));
          var longitudes = List<double>.from(value['long'].map((lng) => lng));
          var points = <LatLng>[];

          for (var i = 0; i < latitudes.length; i++) {
            points.add(LatLng(latitudes[i], longitudes[i]));
          }

          var polyline = Polyline(
            width: 1,
            polylineId:
                PolylineId('polyline$index'), // Unique ID for each polyline
            points: points,
            color: index == 0 ? Colors.blue : Colors.red,
          );

          _polylines.add(polyline);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          'Realtime Navigation',
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.refresh),
            onPressed: () {
              _getMarkers();
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(30.766096510937, 76.57490262300782),
          zoom: 15,
        ),
        polylines: _polylines,
        // markers: _markers,
        circles: _circles,
      ),
    );
  }
}
