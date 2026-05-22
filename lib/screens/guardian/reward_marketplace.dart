import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/reward_model.dart';
import 'package:uuid/uuid.dart';

// ── Emoji picker options ───────────────────────────────────────────────────────
const _emojiOptions = [
  '🎮', '📱', '🍕', '🎬', '📚', '⚽', '🎯', '🏆', '🎁', '💰',
  '🚲', '✈️', '🎧', '🖥️', '🍦', '🏠', '⌚', '🎠', '🎤', '🌟',
];

// ── Provider ──────────────────────────────────────────────────────────────────
final guardianRewardsProvider =
    StreamProvider.autoDispose.family<List<RewardModel>, String>(
  (ref, guardianId) =>
      ref.watch(databaseProvider).getGuardianRewards(guardianId),
);

class RewardMarketplace extends ConsumerStatefulWidget {
  const RewardMarketplace({super.key});

  @override
  ConsumerState<RewardMarketplace> createState() => _RewardMarketplaceState();
}

class _RewardMarketplaceState extends ConsumerState<RewardMarketplace> {
  final _titleCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  String _selectedEmoji = '🎁';
  bool _publishing = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishReward(String guardianId) async {
    if (_titleCtrl.text.trim().isEmpty || _costCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in both title and point cost.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    final cost = int.tryParse(_costCtrl.text.trim());
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid point cost greater than 0.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _publishing = true);
    try {
      final reward = RewardModel(
        id: const Uuid().v4(),
        guardianId: guardianId,
        title: _titleCtrl.text.trim(),
        pointCost: cost,
        iconEmoji: _selectedEmoji,
      );
      await ref.read(databaseProvider).addReward(reward);
      _titleCtrl.clear();
      _costCtrl.clear();
      setState(() => _selectedEmoji = '🎁');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Reward published!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _deleteReward(String guardianId, RewardModel reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reward?'),
        content: Text('Are you sure you want to delete "${reward.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(databaseProvider).deleteReward(guardianId, reward.id);
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pick an icon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _emojiOptions.map((e) {
                final selected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmoji = e);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : null,
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 26))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reward Marketplace')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          final rewardsAsync =
              ref.watch(guardianRewardsProvider(user.uid));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Add new reward ────────────────────────────────────
                Text('Add New Reward',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Emoji picker button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showEmojiPicker,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Text(_selectedEmoji,
                                    style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Reward Title',
                                prefixIcon: Icon(Icons.card_giftcard_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Point Cost',
                          prefixIcon: Icon(Icons.star_border_rounded),
                          suffixText: 'pts',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed:
                            _publishing ? null : () => _publishReward(user.uid),
                        icon: _publishing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.publish_rounded),
                        label: const Text('Publish Reward'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
                Text('Published Rewards',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // ── Rewards list ──────────────────────────────────────
                rewardsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (rewards) {
                    if (rewards.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.card_giftcard_outlined,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No rewards yet. Add one above!',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: rewards.map((reward) {
                        return Dismissible(
                          key: Key(reward.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 28),
                          ),
                          onDismissed: (_) =>
                              _deleteReward(user.uid, reward),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      reward.iconEmoji ?? '🎁',
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reward.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${reward.pointCost} points',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.swipe_left_rounded,
                                    color: Colors.grey.shade300, size: 20),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
