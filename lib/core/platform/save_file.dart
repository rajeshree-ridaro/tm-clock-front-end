/// Saves text as a file: a browser download on web. Returns false where that isn't available.
library;

export 'save_file_stub.dart' if (dart.library.js_interop) 'save_file_web.dart';
