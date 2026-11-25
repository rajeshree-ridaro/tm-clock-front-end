import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';

/// Phone → SMS code. The router moves on to company picker / home once the session starts.
/// TODO: PIN step for shared phones / kiosk (`POST /auth/pin`).
class CrewSignInPage extends StatefulWidget {
  const CrewSignInPage({super.key});

  @override
  State<CrewSignInPage> createState() => _CrewSignInPageState();
}

class _CrewSignInPageState extends State<CrewSignInPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        await context.repos.auth.sendOtp(_phone.text.trim());
        setState(() => _codeSent = true);
      });

  Future<void> _verify() => _run(() async {
        final s = context.services;
        final result = await s.repos.auth.verifyOtp(_phone.text.trim(), _code.text.trim());
        await s.session.start(result, client: s.client);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final big = text.headlineSmall?.copyWith(fontSize: 24, letterSpacing: _codeSent ? 6 : 0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CrewTopBar(),
            Expanded(
              child: CrewBody(
                children: [
                  const SizedBox(height: 24),
                  Text(context.t('signIn'), style: text.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent ? '${context.t('codeSent')} ${_phone.text}' : context.t('phoneSub'),
                    style: text.bodyLarge?.copyWith(color: c.soft),
                  ),
                  const SizedBox(height: 28),
                  Text(context.t(_codeSent ? 'code' : 'phone'), style: text.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    key: ValueKey(_codeSent),
                    controller: _codeSent ? _code : _phone,
                    autofocus: true,
                    style: big,
                    keyboardType: _codeSent ? TextInputType.number : TextInputType.phone,
                    autofillHints: [_codeSent ? AutofillHints.oneTimeCode : AutofillHints.telephoneNumber],
                    inputFormatters: _codeSent
                        ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]
                        : [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]'))],
                    decoration: InputDecoration(
                      hintText: _codeSent ? '000000' : '+1 407 555 0110',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BigButton(
                    label: context.t(_codeSent ? 'continue' : 'sendCode'),
                    busy: _busy,
                    onPressed: _codeSent ? _verify : _sendCode,
                  ),
                  if (_codeSent)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton(
                        onPressed: () => setState(() {
                          _codeSent = false;
                          _code.clear();
                        }),
                        child: Text(context.t('changePhone')),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
