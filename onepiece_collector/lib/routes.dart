import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/set_detail_page.dart';
import 'pages/rare_page.dart';
import 'pages/add_card_page.dart';
import 'pages/all_rare_cards_page.dart';
import 'pages/all_valuable_cards_page.dart';
import 'pages/search_card_page.dart';
import 'pages/sets_checkpoint_page.dart';
import 'widgets/bottom_nav.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'controllers/collection_controller.dart';
import 'data/services/connection_service.dart';

/// App router configuration using GoRouter (Navigator 2.0)
/// Routes: /home, /set/:id, /rare, /add-card, /all-rare, /all-valuable
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/set/:id',
          pageBuilder: (context, state) {
            final setId = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: SetDetailPage(setId: setId),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/rare',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RarePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/all-rare',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AllRareCardsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/all-valuable',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AllValuableCardsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/add-card',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddCardPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeOutQuart));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/search-card',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SearchCardPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeOutQuart));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/sets-checkpoint',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SetsCheckpointPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
  ],
);

/// Main scaffold with persistent bottom navigation
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Watch loading state
    final isLoading = context.watch<CollectionController>().isLoading;
    // Watch connection state
    final isOffline = context.watch<ConnectionService>().isOffline;

    // Update current index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home' || location.startsWith('/set/')) {
      _currentIndex = 0;
    } else if (location == '/rare') {
      _currentIndex = 1;
    } else if (location == '/add-card') {
      _currentIndex = 2;
    }

    // Check orientation
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    // Navigation callback
    void onNavTap(int index) {
      if (isLoading) return; // Double check safety
      setState(() => _currentIndex = index);
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/rare');
          break;
        case 2:
          context.go('/add-card');
          break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Row(
        children: [
          // Side Navigation for Landscape
          if (isLandscape)
            NavigationRail(
              backgroundColor: AppColors.darkBlue,
              selectedIndex: _currentIndex,
              onDestinationSelected: onNavTap,
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              selectedIconTheme: const IconThemeData(color: AppColors.cyan),
              unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
              groupAlignment: 0.0,
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.collections_bookmark_outlined),
                  selectedIcon: Icon(Icons.collections_bookmark),
                  label: Text('Collection'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.star_outline),
                  selectedIcon: Icon(Icons.star),
                  label: Text('Rare'),
                ),
                NavigationRailDestination(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple.withOpacity(0.8),
                          AppColors.cyan.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.white),
                  ),
                  selectedIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple, AppColors.cyan],
                      ),
                      shape: BoxShape.circle,
                        boxShadow: [
                        BoxShadow(
                          color: AppColors.purple,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: AppColors.white),
                  ),
                  label: const Text('Add'),
                ),
              ],
            ),

          if (isLandscape)
            VerticalDivider(width: 1, thickness: 1, color: AppColors.glassBorder),

          // Main vertical content
          Expanded(
            child: Column(
              children: [
                // Offline Indicator
                if (isOffline)
                  Container(
                    width: double.infinity,
                    color: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                        const SizedBox(width: 8),
                        const Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Page Content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isLandscape 
          ? null 
          : BottomNav(
              currentIndex: _currentIndex,
              isDisabled: isLoading,
              onTap: onNavTap,
            ),
    );
  }
}
