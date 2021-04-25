import 'package:ask_help_app/models/address.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppData extends ChangeNotifier {
  Address _address;
  GoogleMapController _googleMapController;

  Address get address => _address;
  GoogleMapController get googleMapController => _googleMapController;

  Set<Marker> _markerSet = {};
  Set<Circle> _circleSet = {};

  Set<Marker> get markerSet => _markerSet;
  Set<Circle> get circleSet => _circleSet;

  void set markerSet(Set<Marker> markers) {
    _markerSet = markers;
    print('marker set $markerSet');
    notifyListeners();
  }

  updatePickUpLocationAddress(Address address) {
    _address = address;
    notifyListeners();
  }

  initializeGoogleMapController(GoogleMapController googleMapController) {
    _googleMapController = googleMapController;
    notifyListeners();
  }
}
