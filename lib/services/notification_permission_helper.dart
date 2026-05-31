import 'notification_permission_helper_stub.dart'
    if (dart.library.js) 'notification_permission_helper_web.dart';

Future<String> requestWebNotificationPermission() {
  return requestNotificationPermissionImpl();
}

String getWebNotificationPermissionStatus() {
  return getNotificationPermissionStatusImpl();
}
