import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/sms_detection/controllers/sms_detection_controller.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoMoShieldApp());
}

class MoMoShieldApp extends StatefulWidget {
  const MoMoShieldApp({super.key});

  @override
  State<MoMoShieldApp> createState() => _MoMoShieldAppState();
}

class _MoMoShieldAppState extends State<MoMoShieldApp>
    with WidgetsBindingObserver {
  late SmsDetectionController _smsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _smsController = SmsDetectionController();
    _handleAppLaunch();
  }

  void _handleAppLaunch() {
    // Check if app was launched from fraud notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handle deep link or notification launch here
      _checkForFraudAlert();
    });
  }

  void _checkForFraudAlert() {
    // This would be implemented to handle notification launches
    // For now, just ensure protection is active
    if (_smsController.hasPermissions && !_smsController.isListening) {
      _smsController.startRealTimeDetection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - ensure listening is active
        if (_smsController.hasPermissions && !_smsController.isListening) {
          _smsController.startRealTimeDetection();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Keep listening in background - don't stop
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _smsController),
      ],
      child: MaterialApp(
        title: 'MoMoShield',
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
