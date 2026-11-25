import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool saveTextFile(String fileName, String text, {String mimeType = 'text/plain'}) {
  final blob = web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
