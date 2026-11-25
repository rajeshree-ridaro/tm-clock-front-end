/// "Save as PDF": opens the browser's print dialog (which offers Save as PDF) on web.
/// Returns false where printing isn't available (phones), so the caller can explain.
///
/// TODO: server-rendered official PDFs (`POST /pdf`, docs/API.md §11).
library;

export 'print_page_stub.dart' if (dart.library.js_interop) 'print_page_web.dart';
