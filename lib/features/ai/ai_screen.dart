import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// Hub screen that opens the structured AI Insights and the AI Chat.
/// Replaces the legacy inline-AI screen so the tab still has a landing
/// page while we keep the bottom-nav route `/app/ai` intact.
class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().user?.businessId;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    if (businessId == null) {
      return Scaffold(
        body: Center(child: Text(l.aiSignInRequired)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.aiTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights),
              title: Text(l.aiInsights),
              subtitle: Text(l.aiInsightsSub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/app/ai/insights'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(l.aiChat),
              subtitle: Text(l.aiChatSub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/app/ai/chat'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.aiFreeTierNotice,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
