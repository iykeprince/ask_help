import 'dart:math';
import 'dart:ui' as ui;

import 'package:ask_help_app/data_handlers/app_data.dart';
import 'package:ask_help_app/models/address.dart';
import 'package:ask_help_app/services/request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class HelperService {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = '';
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey';

    var response = await RequestService.getRequest(url);
    if (response != "failed") {
      placeAddress = response["results"][0]["formatted_address"];
      print('place address: $placeAddress');

      Address userPickUpAddress = Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }

  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }
}
