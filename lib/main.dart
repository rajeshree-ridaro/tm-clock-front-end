import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/crew_app.dart';
import 'package:tm_clock/apps/portal/portal_app.dart';

/// Default entry: web → portal, phone → crew app.
/// Use `-t lib/main_portal.dart` or `-t lib/main_crew.dart` to force one.
void main() => runApp(kIsWeb ? const PortalApp() : const CrewApp());
