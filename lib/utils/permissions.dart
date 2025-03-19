import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await Permission.microphone.request();
  await Permission.phone.request();
  await Permission.location.request();
  await Permission.storage.request();
}
