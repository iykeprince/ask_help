import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_fonts/google_fonts.dart';

class CustomMarkerWidget extends StatelessWidget {
  final String username;
  final double duration;
  final String imageUrl;
  const CustomMarkerWidget({
    Key key,
    this.username,
    this.duration,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: [
        Positioned(
          bottom: -10,
          left: 25,
          child: Transform.rotate(
            angle: -pi / 4,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.yellow,
                radius: 15,
              ),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '$username',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '$duration mins',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
