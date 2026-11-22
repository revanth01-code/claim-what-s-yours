import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/shared/widgets/app_error.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'admin_providers.dart';
import 'widgets/admin_pending_table.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_stats_overview.dart';

/// Main administrator dashboard displaying overview metrics and the pending verification queue.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final pendingState = ref.watch(adminPendingNotifierProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 840;

        Widget content = pendingState.when(
          loading: () => const Center(
            child: AppLoading(message: 'Loading pending verification queue...'),
          ),
          error: (error, stack) => Center(
            child: AppError(
              title: 'Failed to load pending queue',
              message: error.toString(),
              onRetry: () => ref.read(adminPendingNotifierProvider.notifier).refresh(),
            ),
          ),
          data: (page) {
            final query = _searchCtrl.text.trim().toLowerCase();
            final filteredItems = query.isEmpty
                ? page.items
                : page.items.where((s) {
                    return s.name.toLowerCase().contains(query) ||
                        s.administeringAuthority.toLowerCase().contains(query) ||
                        s.category.toLowerCase().contains(query);
                  }).toList();

            return RefreshIndicator(
              onRefresh: () => ref.read(adminPendingNotifierProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Title & Context
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scholarship Verification Dashboard',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review official sources and eligibility criteria before publishing to student catalogue.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Overview Cards
                    AdminStatsOverview(
                      scholarships: page.items,
                      totalCount: page.total,
                    ),
                    const SizedBox(height: 24),

                    // Search & Actions Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Filter by scholarship name, authority, or category...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pending Queue
                    AdminPendingTable(
                      scholarships: filteredItems,
                      onRefresh: () => ref.read(adminPendingNotifierProvider.notifier).refresh(),
                    ),

                    // Pagination controls if multiple pages exist
                    if (page.totalPages > 1) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: page.page > 1
                                ? () => ref
                                    .read(adminPendingNotifierProvider.notifier)
                                    .goToPage(page.page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Previous'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Page ${page.page} of ${page.totalPages}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: page.page < page.totalPages
                                ? () => ref
                                    .read(adminPendingNotifierProvider.notifier)
                                    .goToPage(page.page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );

        if (isDesktop) {
          // Desktop split view with persistent sidebar
          return Scaffold(
            body: Row(
              children: [
                AdminSidebar(
                  currentUser: authState.user,
                  selectedRoute: RoutePaths.admin,
                  onSignOut: () {
                    ref.read(authNotifierProvider.notifier).signOut();
                    context.go(RoutePaths.home);
                  },
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        // Mobile / Tablet layout with Drawer
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Student Catalogue',
                icon: const Icon(Icons.school_outlined),
                onPressed: () => context.go(RoutePaths.scholarships),
              ),
            ],
          ),
          drawer: Drawer(
            child: AdminSidebar(
              currentUser: authState.user,
              selectedRoute: RoutePaths.admin,
              onSignOut: () {
                Navigator.of(context).pop();
                ref.read(authNotifierProvider.notifier).signOut();
                context.go(RoutePaths.home);
              },
            ),
          ),
          body: content,
        );
      },
    );
  }
}
