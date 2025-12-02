import 'package:permission_handler/permission_handler.dart';

class SmsPermissionService {
  static final SmsPermissionService _instance = SmsPermissionService._internal();
  factory SmsPermissionService() => _instance;
  SmsPermissionService._internal();

  Future<bool> hasPermissions() async {
    final smsPermission = await Permission.sms.status;
    final phonePermission = await Permission.phone.status;
    
    return smsPermission.isGranted && phonePermission.isGranted;
  }

  Future<bool> requestPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
    ].request();

    return statuses[Permission.sms]?.isGranted == true &&
           statuses[Permission.phone]?.isGranted == true;
  }

  Future<PermissionStatus> getSmsPermissionStatus() async {
    return await Permission.sms.status;
  }

  Future<PermissionStatus> getPhonePermissionStatus() async {
    return await Permission.phone.status;
  }

  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
