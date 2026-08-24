import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/ai_insight.dart';
import '../../providers/ai_provider.dart';

/// Renders a structured [AiResult]: summary, key findings, recommendations,
/// confidence badge. Falls back to friendly text when the backend is
/// offline (AI failures never crash the rest of the app).
class AiInsightsScreen extends StatefulWidget {
  final String businessId;

  const AiInsightsScreen({super.key, required this.businessId});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  AiInsightType _selected = AiInsightType.monthly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInsight();
    });
  }

  Future<void> _runInsight() async {
    final provider = context.read<AiProvider>();
    await provider.generateInsight(
      businessId: widget.businessId,
      type: _selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aiInsights)),
      body: Consumer<AiProvider>(
        builder: (context, ai, _) {
          final result = ai.lastInsight;
          return RefreshIndicator(
            onRefresh: _runInsight,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TypeSelector(
                  selected: _selected,
                  onChanged: (t) {
                    setState(() => _selected = t);
                    _runInsight();
                  },
                ),
                const SizedBox(height: 16),
                if (ai.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (ai.errorMessage != null)
                  _ErrorCard(
                    message: ai.errorMessage!,
                    onRetry: () {
                      ai.clearError();
                      _runInsight();
                    },
                  )
                else if (result == null || result.isEmpty)
                  const _EmptyState()
                else
                  _InsightCard(result: result),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final AiInsightType selected;
  final ValueChanged<AiInsightType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AiInsightType.values.map((type) {
          final isSelected = type == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type.displayLabel),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AiResult result;
  const _InsightCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.type.displayLabel,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _ConfidenceBadge(confidence: result.confidence),
              ],
            ),
            const SizedBox(height: 12),
            Text(result.summary, style: theme.textTheme.bodyMedium),
            if (result.keyFindings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.aiKeyFindings,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...result.keyFindings.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(f)),
                    ],
                  ),
                ),
              ),
            ],
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.aiRecommendations,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...result.recommendations.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('→ '),
                      Expanded(child: Text(r)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = switch (confidence) {
      'high' => Colors.green,
      'medium' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        l.aiConfidence(confidence.toUpperCase()),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text(
                  l.aiOffline,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.commonRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.insights, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              l.aiInsightsEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}