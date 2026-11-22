import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/applications/domain/application_record.dart';
import 'package:claim_whats_yours/features/applications/presentation/applications_providers.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/eligibility/domain/eligibility_models.dart';
import 'package:claim_whats_yours/features/eligibility/presentation/eligibility_providers.dart';
import 'package:claim_whats_yours/features/notifications/presentation/notifications_providers.dart';
import 'package:claim_whats_yours/features/profile/presentation/profile_providers.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/presentation/scholarship_list_controller.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

/// Production-ready Personalized Student Dashboard.
/// Fully connected to real APIs:
/// - Student Profile completion & personal data
/// - Rule-based deterministic eligibility engine results
/// - Application tracking & timeline events
/// - Saved / bookmarked scholarships
/// - Real official deadline dates
/// - In-app notifications with unread counts
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

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Consumer(
          builder: (context, ref, _) {
            final theme = Theme.of(context);
            final notifsAsync = ref.watch(myNotificationsProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollCtrl) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications & Alerts',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref.read(notificationsRepositoryProvider).markAllRead();
                              ref.invalidate(myNotificationsProvider);
                              ref.invalidate(unreadNotificationsCountProvider);
                            },
                            child: const Text('Mark all as read'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: notifsAsync.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const Center(
                                child: Text('No notifications yet. You are all caught up!'),
                              );
                            }
                            return ListView.separated(
                              controller: scrollCtrl,
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final n = items[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: n.isRead ? Colors.grey.shade300 : AppColors.teal,
                                    radius: 6,
                                  ),
                                  title: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(n.message),
                                  trailing: Text(
                                    '${n.createdAt.day}/${n.createdAt.month}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  onTap: () async {
                                    if (!n.isRead) {
                                      await ref.read(notificationsRepositoryProvider).markRead(n.id);
                                      ref.invalidate(myNotificationsProvider);
                                      ref.invalidate(unreadNotificationsCountProvider);
                                    }
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error loading alerts: $e')),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddApplicationDialog(BuildContext context) {
    final schList = ref.read(scholarshipListControllerProvider).items.where((s) => s.isActive).toList();
    if (schList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active scholarships available to track.')),
      );
      return;
    }

    String selectedSchId = schList.first.id;
    final portalCtrl = TextEditingController(text: 'National Scholarship Portal (NSP)');
    final refNumCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedStatus = 'submitted';

    showDialog<void>(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('Track Scholarship Application'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSchId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Scholarship'),
                      items: schList.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => selectedSchId = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: portalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Portal / Office',
                        hintText: 'e.g. Telangana ePASS or NSP',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refNumCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Application Reference Number *',
                        hintText: 'e.g. NSP-2026-123456',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Current Status'),
                      items: const [
                        DropdownMenuItem(value: 'interested', child: Text('Interested')),
                        DropdownMenuItem(value: 'preparing', child: Text('Preparing Documents')),
                        DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                        DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'disbursed', child: Text('Disbursed')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDlgState(() => selectedStatus = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expected / Sanctioned Amount (₹)',
                        hintText: 'e.g. 25000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'e.g. Submitted income certificate at college desk',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final refNum = refNumCtrl.text.trim();
                    if (refNum.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter reference number')),
                      );
                      return;
                    }
                    Navigator.pop(dlgCtx);
                    try {
                      final parsedAmount = double.tryParse(amountCtrl.text.trim());
                      await ref.read(applicationRepositoryProvider).createApplication(
                            scholarshipId: selectedSchId,
                            portalName: portalCtrl.text.trim(),
                            applicationReferenceNumber: refNum,
                            status: selectedStatus,
                            appliedAmount: parsedAmount,
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          );
                      ref.invalidate(myApplicationsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Application tracked successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save application: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final scholarshipState = ref.watch(scholarshipListControllerProvider);
    final completionAsync = ref.watch(studentProfileCompletionProvider);
    final eligibilityAsync = ref.watch(studentBatchEligibilityProvider);
    final applicationsAsync = ref.watch(myApplicationsProvider);
    final savedSchAsync = ref.watch(savedScholarshipsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    final user = authState.user;
    final greetingName = user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'Scholar';

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
                color: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
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
          if (user?.isAdmin == true)
            TextButton.icon(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text('Admin Dashboard'),
              onPressed: () => context.go(RoutePaths.admin),
            ),
          // Notification Bell with Badge
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: (unreadCountAsync.asData?.value ?? 0) > 0,
              label: Text('${unreadCountAsync.asData?.value ?? 0}'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            onPressed: () => _showNotificationsSheet(context),
          ),
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
          ref.invalidate(studentBatchEligibilityProvider);
          ref.invalidate(myApplicationsProvider);
          ref.invalidate(savedScholarshipsProvider);
          ref.invalidate(unreadNotificationsCountProvider);
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
                // 1. Personalized Hero Greeting
                _buildHeroBanner(context, greetingName, user?.isAdmin ?? false),
                const SizedBox(height: 20),

                // 2. Profile Completion Alert
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

                // 3. Quick Action Buttons
                _buildQuickActions(context),
                const SizedBox(height: 28),

                // 4. Deterministic Eligibility Matching Section
                if (authState.isAuthenticated) ...[
                  _buildEligibilitySection(context, eligibilityAsync),
                  const SizedBox(height: 28),
                ],

                // 5. Application Tracking Section
                if (authState.isAuthenticated) ...[
                  _buildApplicationsSection(context, applicationsAsync),
                  const SizedBox(height: 28),
                ],

                // 6. Saved Scholarships Section
                if (authState.isAuthenticated) ...[
                  _buildSavedScholarshipsSection(context, savedSchAsync),
                  const SizedBox(height: 28),
                ],

                // 7. Official Verified Deadlines Section
                _buildDeadlinesSection(context, publishedScholarships),
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
      padding: const EdgeInsets.all(24.0),
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
                child: Text(
                  isAdmin ? 'ADMINISTRATOR' : 'STUDENT DASHBOARD',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Namaste, $name! 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore verified Telangana & Central government scholarships, run explainable eligibility checks, and track your applications.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionBanner(BuildContext context, int percentage) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lavender.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            value: percentage / 100.0,
            strokeWidth: 4,
            backgroundColor: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            color: AppColors.lavender,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile $percentage% Complete',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete your education and financial details for precise scheme matching.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.onboarding),
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.teal),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Sign in to view personalized eligibility matches and track your applications.'),
          ),
          FilledButton.tonal(
            onPressed: () => context.go(RoutePaths.auth),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.search_rounded,
              title: 'Browse Catalogue',
              subtitle: 'Explore schemes',
              color: AppColors.primary,
              onTap: () => context.go(RoutePaths.scholarships),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.auto_awesome,
              title: 'AI Assistant',
              subtitle: 'Telugu & English Q&A',
              color: AppColors.lavender,
              onTap: () => context.push(RoutePaths.assistant),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.assignment_outlined,
              title: 'Track Apps',
              subtitle: 'Reference tracking',
              color: AppColors.teal,
              onTap: () => _showAddApplicationDialog(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.account_circle_outlined,
              title: 'My Profile',
              subtitle: 'Eligibility criteria',
              color: AppColors.coral,
              onTap: () => context.push(RoutePaths.profile),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilitySection(
    BuildContext context,
    AsyncValue<StudentBatchEligibility> asyncVal,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Deterministic Eligibility Matches',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.scholarships),
              child: const Text('View All Schemes'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        asyncVal.when(
          data: (batch) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                ),
              ),
              child: Row(
                children: [
                  _buildStatPill('Eligible', '${batch.eligibleCount}', AppColors.teal, isDark),
                  const SizedBox(width: 12),
                  _buildStatPill('Needs Info', '${batch.needsInfoCount}', AppColors.coral, isDark),
                  const SizedBox(width: 12),
                  _buildStatPill('Ineligible', '${batch.ineligibleCount}', Colors.grey, isDark),
                  const SizedBox(width: 12),
                  _buildStatPill('Pending Verify', '${batch.uncertainCount}', AppColors.lavender, isDark),
                ],
              ),
            );
          },
          loading: () => const AppLoading(message: 'Evaluating eligibility against verified rules...'),
          error: (e, _) => Text('Unable to evaluate eligibility: $e'),
        ),
      ],
    );
  }

  Widget _buildStatPill(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsSection(
    BuildContext context,
    AsyncValue<List<ApplicationRecordItem>> asyncVal,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Application Tracker',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              tooltip: 'Add Tracking Record',
              icon: const Icon(Icons.add_circle_outline, color: AppColors.teal),
              onPressed: () => _showAddApplicationDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        asyncVal.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Track applications you submit on official portals (NSP, ePASS) with reference numbers.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _showAddApplicationDialog(context),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.take(3).length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final app = items[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(app.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(app.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.scholarshipName,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ref: ${app.applicationReferenceNumber} • ${app.portalName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const AppLoading(message: 'Loading tracked applications...'),
          error: (e, _) => Text('Error loading applications: $e'),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disbursed':
        return AppColors.teal;
      case 'rejected':
      case 'withdrawn':
        return Colors.red.shade400;
      case 'under_review':
        return AppColors.lavender;
      case 'submitted':
        return AppColors.primary;
      default:
        return Colors.amber.shade700;
    }
  }

  Widget _buildSavedScholarshipsSection(
    BuildContext context,
    AsyncValue<List<Scholarship>> asyncVal,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Scholarships',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        asyncVal.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                ),
                child: Text(
                  'No scholarships saved yet. Click the bookmark icon on any scholarship to save it here.',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final sch = items[i];
                return ListTile(
                  tileColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                    ),
                  ),
                  title: Text(sch.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(sch.administeringAuthority),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => context.go('${RoutePaths.scholarships}/${sch.id}'),
                );
              },
            );
          },
          loading: () => const AppLoading(message: 'Loading saved scholarships...'),
          error: (e, _) => Text('Error loading saved scholarships: $e'),
        ),
      ],
    );
  }

  Widget _buildDeadlinesSection(BuildContext context, List<Scholarship> scholarships) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final withDeadlines = scholarships.where((s) => s.hasVerifiedSource).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified Schemes & Deadlines',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (withDeadlines.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: const Text('All schemes in catalogue are currently tracked for academic year 2026-27.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: withDeadlines.take(3).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final sch = withDeadlines[i];
              return ListTile(
                tileColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                ),
                leading: const Icon(Icons.verified, color: AppColors.teal),
                title: Text(sch.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Authority: ${sch.administeringAuthority}'),
                trailing: TextButton(
                  onPressed: () => context.go('${RoutePaths.scholarships}/${sch.id}'),
                  child: const Text('View'),
                ),
              );
            },
          ),
      ],
    );
  }
}
