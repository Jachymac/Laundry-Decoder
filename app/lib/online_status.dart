import 'online_status_stub.dart'
    if (dart.library.html) 'online_status_web.dart';

Future<bool> checkOnlineStatus() => getOnlineStatus();
