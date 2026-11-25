import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/crew/router/crew_routes.dart';
import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/repositories/repositories.dart';

/// Clock in / clock out: punch time is the tap → location check → photo → confirm.
///
/// TODO (device integrations, one place each):
/// * GPS: `geolocator` → pass lat/lng to checkLocation + createPunch.
/// * Camera: `camera` / `image_picker` → upload via `POST /files/upload-url` → photoFileId.
/// * Offline: queue the punch locally with the same clientId and sync with `POST /punches/batch`.
/// * Free plan clock-out ad (docs/API.md §Ads).
class ClockPage extends StatefulWidget {
  const ClockPage({super.key, required this.clockOut});
  final bool clockOut;

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  /// Tap time and idempotency key are fixed when the screen opens, so retries never move the punch.
  final DateTime _tapAt = DateTime.now();
  final String _clientId = newClientId();

  // TODO: real position from `geolocator`. Fixed test point near the demo job site until then.
  static const _lat = 28.37, _lng = -81.25;

  late final Future<LocationCheck> _location =
      context.repos.punches.checkLocation(lat: _lat, lng: _lng, accuracyFt: 30);
  bool _photo = false;
  bool _saving = false;

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_photo) {
      messenger.showSnackBar(SnackBar(content: Text(context.t('photoFirst'))));
      return;
    }
    final done = context.t(widget.clockOut ? 'clockOut' : 'clockedIn');
    setState(() => _saving = true);
    try {
      final loc = await _location;
      if (!mounted) return;
      await context.repos.punches.createPunch(
        clientId: _clientId,
        kind: widget.clockOut ? PunchKind.clockOut : PunchKind.clockIn,
        deviceAt: _tapAt,
        siteId: loc.site?.id,
        lat: _lat,
        lng: _lng,
      );
      messenger.showSnackBar(SnackBar(content: Text('$done ✓')));
      if (mounted) context.go(CrewRoutes.home);
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final time = TimeOfDay.fromDateTime(_tapAt).format(context);

    Widget banner(IconData icon, String msg, {required Color bg, required Color fg}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
          ]),
        );

    return CrewBody(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(CrewRoutes.home),
            icon: const Icon(Icons.chevron_left_rounded),
            label: Text(context.t('back')),
            style: TextButton.styleFrom(foregroundColor: c.ink, padding: EdgeInsets.zero),
          ),
        ),
        Text(context.t(widget.clockOut ? 'clockOut' : 'clockIn'), style: text.headlineLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 16),
        banner(Icons.check_rounded, '${context.t('punchSaved')} $time', bg: c.okBg, fg: c.ok),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: c.photo,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _photo = !_photo),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_photo ? Icons.check_circle_rounded : Icons.photo_camera_outlined,
                        size: 44, color: _photo ? c.ok : c.soft),
                    const SizedBox(height: 12),
                    Text(context.t(_photo ? 'photoReady' : 'takePhoto'), style: text.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      _photo ? context.t('retake') : context.t('takePhotoSub'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.mute, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<LocationCheck>(
          future: _location,
          builder: (context, snap) {
            final loc = snap.data;
            if (loc == null) {
              return banner(Icons.my_location_rounded, context.t('checkingLoc'), bg: c.raise, fg: c.soft);
            }
            final msg = '${context.t('youAreAt')} ${loc.site?.name ?? '—'} · ${loc.distanceFt} ft';
            return loc.inside
                ? banner(Icons.place_outlined, msg, bg: c.okBg, fg: c.ok)
                : banner(Icons.wrong_location_outlined, msg, bg: c.noBg, fg: c.red);
          },
        ),
        const SizedBox(height: 16),
        BigButton(
          label: context.t(widget.clockOut ? 'confirmOut' : 'confirmIn'),
          danger: widget.clockOut,
          busy: _saving,
          onPressed: _confirm,
        ),
      ],
    );
  }
}
