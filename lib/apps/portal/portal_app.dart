import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/router/portal_router.dart';
import 'package:tm_clock/core/app/tm_app.dart';
import 'package:tm_clock/core/theme/tm_theme.dart';

/// Web portal for owners, office admins and supervisors.
class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) => const TmApp(
        flavor: TmFlavor.portal,
        title: 'TM Clock Portal',
        buildRouter: buildPortalRouter,
      );
}
