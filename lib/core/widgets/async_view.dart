import 'package:flutter/material.dart';

import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/api/api_client.dart';

/// Loading / error / data for one repository call. Both apps use it so every
/// screen handles loading and API errors the same way.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, this.onRetry});

  final Future<T> future;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          final e = snap.error;
          final msg = e is ApiException ? e.message : '$e';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.cloud_off_rounded, color: context.tm.red, size: 32),
                const SizedBox(height: 8),
                Text(msg, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ],
            ),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return builder(snap.data as T);
      },
    );
  }
}
