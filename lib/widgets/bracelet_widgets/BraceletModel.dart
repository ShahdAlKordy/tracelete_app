class BraceletModel {
  String id;
  String name;
  bool isConnected;
  double batteryLevel;

  BraceletModel({
    required this.id,
    required this.name,
    this.isConnected = true,
    this.batteryLevel = 1.0,
  });
}