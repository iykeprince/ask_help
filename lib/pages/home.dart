import 'dart:async';

import 'package:ask_help_app/data_handlers/app_data.dart';
import 'package:ask_help_app/main.dart';
import 'package:ask_help_app/models/nearby_user.dart';
import 'package:ask_help_app/pages/login.dart';
import 'package:ask_help_app/services/geo_service.dart';
import 'package:ask_help_app/services/helper_service.dart';
import 'package:ask_help_app/services/push_notification_service.dart';
import 'package:ask_help_app/widget/custom_marker.dart';
import 'package:ask_help_app/widget/help_dialog.dart';
import 'package:ask_help_app/widget/ripple_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_animarker/flutter_map_marker_animation.dart';
import 'package:share/share.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _requestForHelp = false;
  final markerKey = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String name, email;

  TextEditingController _currentLocationTextEditingController =
      TextEditingController();
  Position mPosition;
  double mRadius = 50;
  final geo = GeoFlutterFire();
  StreamSubscription<Position> _streamSubscription;
  StreamSubscription<List<DocumentSnapshot>> _queryStreamSubscription;
  AppData appData;

  BitmapDescriptor nearbyIcon;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    'notification_${mUser.uid}', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  @override
  void initState() {
    super.initState();

    requestLocationStatus();
  }

  void requestLocationStatus() async {
    LocationPermission permission;

    bool _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled)
      return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    mPosition = await Geolocator.getCurrentPosition();
    initializePushNotificationService();
  }

  initializePushNotificationService() async {
    PushNotification pushNotification = PushNotification();
    pushNotification.initialize();
    pushNotification.getToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: 'launch_background',
              ),
            ));
      }
    });
  }

  initializeGeoFirestore() async {
    GeoFirePoint myLocation =
        geo.point(latitude: mPosition.latitude, longitude: mPosition.longitude);

    locations
        .doc(mUser.uid)
        .set({"name": name, "need_help": false, "position": myLocation.data});
  }

  shareLiveLocation() {
    _streamSubscription =
        Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high)
            .listen((Position position) {
      mPosition = position;
      print(
          'live coordinates -> latitude: ${mPosition.latitude} longitude: ${mPosition.longitude}');
      GeoFirePoint myLocation =
          geo.point(latitude: position.latitude, longitude: position.longitude);
      locations.doc(mUser.uid).update(
          {'name': name, 'need_help': true, 'position': myLocation.data});

      LatLng latLng = LatLng(position.latitude, position.longitude);
      Provider.of<AppData>(context, listen: false)
          .googleMapController
          .animateCamera(CameraUpdate.newLatLng(latLng));

      queryGeoFirestore();
    });
    setState(() {});
  }

  _shareLocationHandler(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;

    await Share.share(
      "$name is currently at ${_currentLocationTextEditingController.text}",
      subject: "$name's location",
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
  }

  askHelpHandler() async {
    shareLiveLocation();
  }

  queryGeoFirestore() {
    GeoFirePoint center =
        geo.point(latitude: mPosition.latitude, longitude: mPosition.longitude);

    String field = 'position';

    Stream<List<DocumentSnapshot>> stream =
        geo.collection(collectionRef: locations).within(
              center: center,
              radius: mRadius,
              field: field,
            );
    _queryStreamSubscription =
        stream.listen((List<DocumentSnapshot> documentSnapshot) {
      if (documentSnapshot != null) {
        print('Querying GEOFIRE!!!');
        print('documents: ${documentSnapshot.length}');
        documentSnapshot.forEach((document) {
          var data = document.data();
          String username = data['name'];
          GeoPoint point = data['position']['geopoint'];
          print(
              'Geopoint -> latitude: ${point.latitude} longitude: ${point.longitude}');
          NearbyUser nearbyUser = NearbyUser();
          nearbyUser.geohash = data['geohash'];
          nearbyUser.username = username;
          nearbyUser.needHelp = data['need_help'];
          nearbyUser.latitude = point.latitude;
          nearbyUser.longitude = point.longitude;
          nearbyUser.distance =
              center.distance(lat: point.latitude, lng: point.longitude);

          GeoService.nearbyUserList.add(nearbyUser);

          updateAvailableUsersOnMap(nearbyUser.needHelp);
        });
      }
      setState(() {});
    });
  }

  updateAvailableUsersOnMap(bool needHelp) {
    print('need help value: $needHelp');
    setState(() {
      appData.markerSet.clear();
    });
    Set<Marker> tMarkers = Set<Marker>();
    for (NearbyUser nearbyUser in GeoService.nearbyUserList) {
      LatLng availableUserPosition =
          LatLng(nearbyUser.latitude, nearbyUser.longitude);

      Marker marker = RippleMarker(
        markerId: MarkerId('driver${nearbyUser.geohash}'),
        position: availableUserPosition,
        rotation: HelperService.createRandomNumber(360),
        infoWindow: InfoWindow(
          title: nearbyUser.username,
          snippet: '${nearbyUser.distance.toString()} KM',
        ),
        ripple: true,
      );

      tMarkers.add(marker);
    }

    appData.markerSet = tMarkers;
    print('app data markerset: ${tMarkers.length}');
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _queryStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    appData = Provider.of<AppData>(context);
    _currentLocationTextEditingController.text = appData.address?.placeName;

    if (mUser != null) {
      users.doc(mUser.uid).get().then((value) {
        var data = value.data();
        print('data ${data['name']}');
        name = data['name'];
        email = data['email'];
      });
    }
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
          child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                        'https://source.unsplash.com/random/100x100'),
                  ),
                  SizedBox(height: 8),
                  Text(name ?? ''),
                  Text(email ?? ''),
                ],
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                InkWell(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Login(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      )
          //
          ),
      body: SafeArea(
        child: Stack(
          children: [
            MapWidget(),
            Positioned(
              top: 10,
              left: 8,
              right: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        InkWell(
                            onTap: () {
                              _scaffoldKey.currentState.openDrawer();
                            },
                            child: Icon(Icons.menu_sharp)),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _currentLocationTextEditingController,
                            decoration: InputDecoration(
                              hintText: 'Current Location',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                          ),
                          onPressed: null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _shareLocationHandler(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 8.0,
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
                              primary: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Share Live Location',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              initializeGeoFirestore();
                              queryGeoFirestore();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 8.0,
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
                              primary: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Ask For Help',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.location_history_outlined,
                              size: 24,
                              color: Colors.white,
                            ),
                            onPressed: null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.contact_phone,
                              size: 24,
                              color: Colors.white,
                            ),
                            onPressed: null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              size: 24,
                              color: Colors.white,
                            ),
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  Completer<GoogleMapController> _controller = Completer();
  // GoogleMapController _googleMapController;

  AppData appData;
  double latitude, longitude;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();

    getLiveLocation();
  }

  getLiveLocation() {
    print('started live');
    Geolocator.getPositionStream().listen((Position position) async {
      latitude = position.latitude;
      longitude = position.longitude;
      // List<Placemark> placemarks =
      //     await placemarkFromCoordinates(position.latitude, longitude);

      print(
          'position: lat - ${position.latitude} & lon - ${position.longitude}');
    });
  }

  @override
  Widget build(BuildContext context) {
    appData = Provider.of<AppData>(context);
    return Animarker(
      curve: Curves.bounceOut,
      duration: Duration(milliseconds: 1300),
      mapId: _controller.future.then<int>((value) => value.mapId),
      rippleRadius: 0.5, //[0,1.0] range, how big is the circle
      rippleColor: Colors.redAccent, // Color of fade ripple circle
      rippleDuration: Duration(milliseconds: 1000), //Pulse ripple duration
      markers: appData.markerSet,
      child: GoogleMap(
        padding: EdgeInsets.only(bottom: 140),
        mapType: MapType.normal,
        markers: appData.markerSet,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          // _googleMapController = controller;
          Provider.of<AppData>(context, listen: false)
              .initializeGoogleMapController(controller);

          locatePosition();
        },
      ),
    );
  }

  locatePosition() async {
    Position position = await Geolocator.getCurrentPosition();

    LatLng latLng = LatLng(position.latitude, position.longitude);
    CameraUpdate cameraUpdate = CameraUpdate.newLatLng(latLng);

    Provider.of<AppData>(context, listen: false)
        .googleMapController
        .animateCamera(cameraUpdate);

    HelperService.searchCoordinateAddress(position, context);

    var marker = RippleMarker(
      markerId: MarkerId('user-' + mUser.uid),
      position: latLng,
      infoWindow: InfoWindow(
        title: 'Username',
        snippet: '4mins',
      ),
      ripple: true,
    );

    setState(() {
      appData.markerSet.add(marker);
    });
  }

  @override
  void dispose() {
    Provider.of<AppData>(context).googleMapController.dispose();
    super.dispose();
  }
}
