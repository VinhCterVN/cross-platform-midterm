import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool downloadJson(String json, String filename) {
  final blob = web.Blob([json.toJS].toJS, web.BlobPropertyBag(type: 'application/json;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(const Duration(seconds: 10), () => web.URL.revokeObjectURL(url));
  return true;
}
