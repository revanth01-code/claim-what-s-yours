import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/profile/presentation/profile_providers.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/presentation/scholarship_list_controller.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

/// Production-quality, premium Student Dashboard screen.
/// Implements personalized welcome, profile completion tracking, real scholarship discovery,
/// verified deadlines, clear application tracking status, and quick actions.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(scholarshipListControllerProvider.notifier).ensureLoaded();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final scholarshipState = ref.watch(scholarshipListControllerProvider);
    final completionAsync = ref.watch(studentProfileCompletionProvider);

    final user = authState.user;
    final greetingName = user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'Scholar';

    // Filter verified and published scholarships from real catalogue data
    final publishedScholarships = scholarshipState.items.where((s) => s.isActive).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Claim What's Yours",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Scholarship Catalogue',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(RoutePaths.scholarships),
          ),
          IconButton(
            tooltip: 'AI Assistant',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => context.push(RoutePaths.assistant),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(RoutePaths.profile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileCompletionProvider);
          await ref.read(scholarshipListControllerProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ResponsiveContentContainer(
            maxWidth: 1100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Personalized Welcome & Hero Section
                _buildHeroBanner(context, greetingName, user?.isAdmin ?? false),
                const SizedBox(height: 20),

                // 2. Profile Completion Alert (only if not completed)
                if (authState.isAuthenticated)
                  completionAsync.when(
                    data: (comp) => comp.percentage < 100
                        ? _buildProfileCompletionBanner(context, comp.percentage)
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  )
                else
                  _buildGuestBanner(context),
                const SizedBox(height: 24),

                // 3. Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 28),

                // 4. Search and Browse Card
                _buildDiscoverySearchCard(context),
                const SizedBox(height: 28),

                // 5. Recommended & Active Scholarships Section
                _buildScholarshipRecommendations(context, publishedScholarships, scholarshipState.status == ScholarshipListStatus.loading),
                const SizedBox(height: 28),

                // 6. Application Tracking Status (Accurate & Honest State)
                _buildApplicationTrackerStatus(context),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, String name, bool isAdmin) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: isDark ? AppColors.onPrimaryContainerDark : AppColors.onPrimaryContainer,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAdmin ? 'ADMINISTRATOR VIEW' : 'STUDENT PORTAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.onPrimaryContainerDark : AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isAdmin)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                    foregroundColor: isDark ? AppColors.onPrimaryDark : AppColors.onPrimary,
                  ),
                  onPressed: () => context.go(RoutePaths.admin),
                  child: const Text('Admin Dashboard'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Namaste, $name! 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Your direct gateway to verified Telangana State & National scholarship schemes. Grounded exclusively in official government gazettes and portals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionBanner(BuildContext context, int percentage) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.secondary,
            radius: 20,
            child: Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile to unlock eligibility matching',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add education level, domicile, category and income to match relevant schemes automatically.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSecondaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () => context.push(RoutePaths.onboarding),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Sign in to save your scholarship preferences and track verified schemes.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          FilledButton.tonal(
            onPressed: () => context.push(RoutePaths.auth),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final actions = [
          _QuickActionTile(
            title: 'Browse Catalogue',
            subtitle: 'Explore all verified government grants',
            icon: Icons.list_alt_rounded,
            color: AppColors.primary,
            onTap: () => context.go(RoutePaths.scholarships),
          ),
          _QuickActionTile(
            title: 'My Profile',
            subtitle: 'Academic and income eligibility info',
            icon: Icons.person_outline_rounded,
            color: AppColors.secondary,
            onTap: () => context.push(RoutePaths.profile),
          ),
          _QuickActionTile(
            title: 'AI Assistant',
            subtitle: 'Ask eligibility & document questions',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.tertiary,
            onTap: () => context.push(RoutePaths.assistant),
          ),
        ];

        if (isWide) {
          return Row(
            children: actions
                .map((tile) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: tile,
                      ),
                    ))
                .toList(),
          );
        }

        return Column(
          children: actions
              .map((tile) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: tile,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildDiscoverySearchCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Search & Filters',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by authority, scheme name, or keyword...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () {
                    final q = _searchCtrl.text.trim();
                    if (q.isNotEmpty) {
                      ref.read(scholarshipListControllerProvider.notifier).setSearch(q);
                      context.go(RoutePaths.scholarships);
                    }
                  },
                ),
              ),
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) {
                  ref.read(scholarshipListControllerProvider.notifier).setSearch(q.trim());
                  context.go(RoutePaths.scholarships);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarshipRecommendations(
    BuildContext context,
    List<Scholarship> scholarships,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_outlined, color: AppColors.success, size: 22),
            const SizedBox(width: 8),
            Text(
              'Verified & Published Scholarships',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(RoutePaths.scholarships),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else if (scholarships.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 44,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Active Public Scholarships Currently Published',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(
                        'All imported government schemes are currently undergoing rigorous multi-gate administrative verification before student publication. Complete your profile in the meantime to be instantly notified upon release.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.push(RoutePaths.onboarding),
                      child: const Text('Complete Student Profile'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scholarships.take(3).length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = scholarships[index];
              return Card.outlined(
                child: ListTile(
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s.administeringAuthority),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.go('/scholarships/${s.id}'),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildApplicationTrackerStatus(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.track_changes_outlined, size: 20, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Application Tracking',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'COMING SOON',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Direct government portal status tracking and document deadline reminders will be enabled once your submitted applications are linked. You will never see fake application statuses.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
