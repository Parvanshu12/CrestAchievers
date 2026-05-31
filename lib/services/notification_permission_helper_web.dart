import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<String> requestNotificationPermissionImpl() async {
  try {
    final status = js.context.callMethod('requestNotificationPermission');
    if (status is String) {
      return status;
    } else if (status != null) {
      return 'granted';
    }
    return 'default';
  } catch (e) {
    debugPrint("Error calling requestNotificationPermission JS: $e");
    return 'default';
  }
}

String getNotificationPermissionStatusImpl() {
  try {
    final status = js.context.callMethod('getNotificationPermissionStatus');
    return status?.toString() ?? 'default';
  } catch (e) {
    return 'default';
  }
}
