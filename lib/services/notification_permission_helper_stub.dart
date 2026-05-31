import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

const _channel = MethodChannel('crestachievers.com/notifications_permission');

Future<String> requestNotificationPermissionImpl() async {
  if (kIsWeb) return 'default';
  
  if (defaultTargetPlatform == TargetPlatform.windows || 
      defaultTargetPlatform == TargetPlatform.macOS || 
      defaultTargetPlatform == TargetPlatform.linux) {
    debugPrint("Official desktop platform notifications enabled.");
    return 'granted';
  }

  try {
    final bool? result = await _channel.invokeMethod<bool>('requestPermission');
    return result == true ? 'granted' : 'denied';
  } on PlatformException catch (e) {
    debugPrint("Failed to request native notification permission: ${e.message}");
    return 'granted';
  } catch (e) {
    debugPrint("Error requesting native notification permission: $e");
    return 'default';
  }
}

String getNotificationPermissionStatusImpl() {
  return 'default';
}
