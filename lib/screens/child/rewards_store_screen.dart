import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/reward_model.dart';

// Fetches rewards from all linked guardians
final childRewardsProvider =
    FutureProvider.autoDispose<List<RewardModel>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.linkedGuardianIds.isEmpty) return [];
  return ref.read(databaseProvider).getChildRewards(user.linkedGuardianIds);
});

class RewardsStoreScreen extends ConsumerWidget {
  const RewardsStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final rewardsAsync = ref.watch(childRewardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards Store')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          return rewardsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rewards) {
              if (rewards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No rewards available yet',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Ask your guardian to add rewards!',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(childRewardsProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final canClaim = user.totalPoints >= reward.pointCost;
                    return _RewardCard(
                      reward: reward,
                      canClaim: canClaim,
                      currentPoints: user.totalPoints,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardModel reward;
  final bool canClaim;
  final int currentPoints;

  const _RewardCard({
    required this.reward,
    required this.canClaim,
    required this.currentPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = reward.iconEmoji ?? '🎁';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: canClaim
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.4), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: canClaim
                    ? theme.colorScheme.primary.withOpacity(0.08)
                    : Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),
          ),

          // Info area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${reward.pointCost} pts',
                  style: TextStyle(
                    color: canClaim
                        ? theme.colorScheme.primary
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: canClaim
                          ? theme.colorScheme.primary
                          : Colors.grey.shade200,
                      foregroundColor:
                          canClaim ? Colors.white : Colors.grey.shade500,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: canClaim
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Reward claimed! Ask your guardian to confirm.'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        : null,
                    child: Text(
                      canClaim
                          ? 'Claim'
                          : '${reward.pointCost - currentPoints} more',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
