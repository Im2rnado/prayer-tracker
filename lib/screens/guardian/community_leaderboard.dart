import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/user_model.dart';

final linkedChildrenProvider =
    StreamProvider.autoDispose.family<List<UserModel>, String>(
  (ref, guardianId) =>
      ref.watch(databaseProvider).getLinkedChildren(guardianId),
);

class CommunityLeaderboard extends ConsumerWidget {
  const CommunityLeaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Leaderboard')),
      body: userAsync.when(
        data: (guardian) {
          if (guardian == null) return const Center(child: Text('Not logged in'));

          final childrenAsync =
              ref.watch(linkedChildrenProvider(guardian.uid));

          return childrenAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (children) {
              if (children.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No children linked yet',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Share your invite code: ${guardian.inviteCode}',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final child = children[index];
                  final rank = index + 1;
                  final isTop3 = rank <= 3;

                  final medalColors = [
                    const Color(0xFFFFD700),
                    const Color(0xFFC0C0C0),
                    const Color(0xFFCD7F32),
                  ];

                  final medalColor =
                      isTop3 ? medalColors[index] : Colors.transparent;

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + index * 50),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: isTop3
                          ? Border.all(color: medalColor, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isTop3
                              ? medalColor.withOpacity(0.2)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: isTop3 ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // Rank badge
                          SizedBox(
                            width: 44,
                            child: isTop3
                                ? Icon(Icons.emoji_events_rounded,
                                    color: medalColor, size: 36)
                                : CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey.shade100,
                                    child: Text(
                                      '$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),

                          // Avatar + name
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              child.name.isNotEmpty
                                  ? child.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  child.email,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Points badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? medalColor.withOpacity(0.12)
                                  : theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${child.totalPoints} pts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isTop3
                                    ? (index == 0
                                        ? const Color(0xFFB8860B)
                                        : index == 1
                                            ? Colors.blueGrey.shade700
                                            : const Color(0xFF8B4513))
                                    : theme.colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
