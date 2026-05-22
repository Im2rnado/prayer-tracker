import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/child/child_dashboard.dart';
import '../../screens/child/log_prayer_screen.dart';
import '../../screens/child/rewards_store_screen.dart';
import '../../screens/child/calendar_screen.dart';
import '../../screens/guardian/guardian_dashboard.dart';
import '../../screens/guardian/rules_config_screen.dart';
import '../../screens/guardian/reward_marketplace.dart';
import '../../screens/guardian/community_leaderboard.dart';
import '../../screens/shared/invite_code_screen.dart';

// Auth State
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to both auth and user data so the router rebuilds when either changes
  final authAsync = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Don't redirect while auth state is still loading
      if (authAsync.isLoading) return null;

      final firebaseUser = authAsync.value;
      final isLoggedIn = firebaseUser != null;
      final isAuthRoute =
          state.uri.path == '/' || state.uri.path == '/register';

      // Not logged in → push to login
      if (!isLoggedIn && !isAuthRoute) return '/';

      // Logged in but on auth route → redirect to the right dashboard
      if (isLoggedIn && isAuthRoute) {
        final userModel = userAsync.value;
        if (userModel == null) return null; // still loading user doc
        return userModel.role == UserRole.guardian ? '/guardian' : '/child';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      // Child Routes
      GoRoute(path: '/child', builder: (context, state) => const ChildDashboard()),
      GoRoute(path: '/child/log-prayer', builder: (context, state) => const LogPrayerScreen()),
      GoRoute(path: '/child/rewards', builder: (context, state) => const RewardsStoreScreen()),
      GoRoute(path: '/child/calendar', builder: (context, state) => const CalendarScreen()),

      // Guardian Routes
      GoRoute(path: '/guardian', builder: (context, state) => const GuardianDashboard()),
      GoRoute(path: '/guardian/rules', builder: (context, state) => const RulesConfigScreen()),
      GoRoute(path: '/guardian/rewards', builder: (context, state) => const RewardMarketplace()),
      GoRoute(path: '/guardian/leaderboard', builder: (context, state) => const CommunityLeaderboard()),

      // Shared Routes
      GoRoute(path: '/shared/invite', builder: (context, state) => const InviteCodeScreen()),
    ],
  );
});
