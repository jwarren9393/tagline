import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nanogpt_catalog.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

Future<void> showCreditsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.inkElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _CreditsSheetBody(),
  );
}

class _CreditsSheetBody extends StatefulWidget {
  const _CreditsSheetBody();

  @override
  State<_CreditsSheetBody> createState() => _CreditsSheetBodyState();
}

class _CreditsSheetBodyState extends State<_CreditsSheetBody> {
  late final Future<NanoGptCredits> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SettingsProvider>().loadCredits();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: FutureBuilder<NanoGptCredits>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Credits', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    '${snap.error}'.replaceFirst('NanoGptException: ', ''),
                    style: const TextStyle(color: AppColors.danger, height: 1.35),
                  ),
                ],
              );
            }
            final c = snap.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Credits', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  const Text(
                    'Refreshed each time this sheet opens.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Text('Wallet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (c.balanceUnavailable)
                    const Text(
                      'Wallet temporarily unavailable.',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else ...[
                    if (c.usdBalance != null)
                      Text('USD balance: \$${c.usdBalance!.toStringAsFixed(2)}'),
                    if (c.nanoBalance != null)
                      Text('NANO balance: ${c.nanoBalance}'),
                    if (c.usdBalance == null && c.nanoBalance == null)
                      const Text(
                        'No wallet balances returned.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Subscription',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (c.subscriptionUnavailable)
                    const Text(
                      'Subscription usage temporarily unavailable.',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else ...[
                    Text(
                      c.subscriptionActive
                          ? 'Active${c.subscriptionState.isEmpty ? '' : ' · ${c.subscriptionState}'}'
                          : 'Inactive${c.subscriptionState.isEmpty ? '' : ' · ${c.subscriptionState}'}',
                    ),
                    if (c.currentPeriodEnd != null)
                      Text(
                        'Period ends: ${c.currentPeriodEnd!.toLocal()}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (c.weeklyTokens != null)
                      _UsageBar(label: 'Weekly input credits', window: c.weeklyTokens!),
                    if (c.dailyTokens != null)
                      _UsageBar(label: 'Daily input credits', window: c.dailyTokens!),
                    if (c.dailyImages != null)
                      _UsageBar(label: 'Daily images', window: c.dailyImages!),
                    if (c.monthlyUsage != null)
                      _UsageBar(label: 'Monthly usage', window: c.monthlyUsage!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.label, required this.window});
  final String label;
  final NanoGptUsageWindow window;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${_fmt(window.used)} used · ${_fmt(window.remaining)} left'
            '${window.limit > 0 ? ' · ${_fmt(window.limit)} limit' : ''}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          if (window.limit > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: window.percentUsed,
                minHeight: 6,
                backgroundColor: AppColors.inkSoft,
                color: AppColors.amber,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n == n.roundToDouble() ? '${n.round()}' : n.toStringAsFixed(1);
  }
}
