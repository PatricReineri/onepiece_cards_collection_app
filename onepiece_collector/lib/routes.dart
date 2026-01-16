import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/set_detail_page.dart';
import 'pages/rare_page.dart';
import 'pages/add_card_page.dart';
import 'pages/all_rare_cards_page.dart';
import 'pages/all_valuable_cards_page.dart';
import 'widgets/bottom_nav.dart';
import 'theme/app_colors.dart';

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
    // Update current index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home' || location.startsWith('/set/')) {
      _currentIndex = 0;
    } else if (location == '/rare') {
      _currentIndex = 1;
    } else if (location == '/add-card') {
      _currentIndex = 2;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: widget.child,
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
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
        },
      ),
    );
  }
}
