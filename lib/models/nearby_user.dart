class NearbyUser {
  String geohash;
  double latitude;
  double longitude;
  double distance;
  String username;
  bool needHelp;

  NearbyUser({
    this.geohash,
    this.username,
    this.latitude,
    this.longitude,
    this.distance,
    this.needHelp,
  });
}
