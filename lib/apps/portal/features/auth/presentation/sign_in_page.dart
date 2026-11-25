import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/auth/presentation/company_chooser.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/core/widgets/theme_lang_controls.dart';
import 'package:tm_clock/core/widgets/tm_logo.dart';

/// Sign in (`.login`): pitch on the left, form on the right; stacks on phones.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final stacked = context.screenWidth < 840;
    const pitch = _Pitch();
    const form = _SignInForm();

    return Scaffold(
      body: stacked
          ? SingleChildScrollView(
              child: Column(
                children: [
                  pitch,
                  Container(color: c.panel, child: form),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: pitch),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.panel,
                      border: Border(left: BorderSide(color: c.line)),
                    ),
                    child: const Center(child: SingleChildScrollView(child: form)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch();

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final big = context.screenWidth >= 1100 ? 44.0 : 32.0;
    Widget bullet(String key) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: c.brandBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.check_rounded, size: 18, color: c.g),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(context.t(key), style: text.bodyMedium)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TmLogo(),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('heroTitle'), style: text.headlineLarge?.copyWith(fontSize: big)),
                const SizedBox(height: 16),
                Text(context.t('heroSub'), style: text.bodyLarge?.copyWith(color: c.soft, fontSize: 17)),
                const SizedBox(height: 24),
                bullet('b1'),
                bullet('b2'),
                bullet('b3'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(context.t('family'), style: TmType.mono(c.mute, size: 12)),
        ],
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Shared flow: repository sign-in → session. One company → the router opens the dashboard;
  /// several → this panel shows the company chooser.
  Future<void> _signIn() async {
    final services = context.services;
    final messenger = ScaffoldMessenger.of(context);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(context.t('needEmailPassword'))));
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await services.repos.auth.loginWithPassword(_email.text.trim(), _password.text);
      await services.session.start(result, client: services.client);
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget field(String key, TextEditingController ctrl, {bool obscure = false, Widget? trailing}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(context.t(key), style: text.titleSmall),
            ?trailing,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(hintText: obscure ? '' : 'name@company.com'),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [ThemeToggleButton(), SizedBox(width: 10), LanguageSwitch()],
          ),
          const SizedBox(height: 40),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ListenableBuilder(
                listenable: context.session,
                builder: (context, _) {
                  final session = context.session;
                  if (session.signedIn && !session.hasCompany) return const CompanyChooser();
                  return _form(context, field);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(
    BuildContext context,
    Widget Function(String, TextEditingController, {bool obscure, Widget? trailing}) field,
  ) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.t('signIn'), style: text.headlineMedium),
        const SizedBox(height: 6),
        Text(context.t('signInSub'), style: text.bodyMedium?.copyWith(color: c.mute)),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: () {}, child: Text(context.t('google'))),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(context.t('or'), style: text.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 18),
        field('email', _email),
        const SizedBox(height: 16),
        field(
          'password',
          _password,
          obscure: true,
          trailing: InkWell(
            onTap: () {},
            child: Text(context.t('forgot'), style: text.labelMedium?.copyWith(color: c.g2)),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _busy ? null : _signIn,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.t('signIn')),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            Text(context.t('newHere'), style: text.bodySmall),
            InkWell(
              onTap: () {},
              child: Text(
                context.t('create'),
                style: text.bodySmall?.copyWith(color: c.g2, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
