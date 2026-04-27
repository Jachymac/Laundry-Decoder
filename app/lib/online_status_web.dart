import 'dart:html' as html;

Future<bool> getOnlineStatus() async {
  return html.window.navigator.onLine ?? false;
}
