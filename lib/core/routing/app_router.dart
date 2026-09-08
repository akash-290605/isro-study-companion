import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai_test/screens/test_builder_screen.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/flashcards/screens/flashcards_screen.dart';
import '../../features/formula_bank/screens/formula_bank_screen.dart';
import '../../features/mistakes/screens/mistakes_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../../features/performance/screens/performance_screen.dart';
import '../../features/question_bank/screens/question_bank_screen.dart';
import '../../features/question_bank/screens/question_detail_screen.dart';
import '../../features/revision/screens/revision_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/source_library/screens/source_library_screen.dart';
import '../../features/syllabus/screens/syllabus_screen.dart';
import '../../features/timer/screens/timer_screen.dart';
import '../services/providers.dart';
import '../widgets/responsive_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = auth.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }
      if (isAuth && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveScaffold(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/timer',
            builder: (context, state) => const TimerScreen(),
          ),
          GoRoute(
            path: '/syllabus',
            builder: (context, state) => const SyllabusScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/uploads',
            redirect: (context, state) => '/question-bank',
          ),
          GoRoute(
            path: '/source-library',
            builder: (context, state) => const SourceLibraryScreen(),
          ),
          GoRoute(
            path: '/question-bank',
            builder: (context, state) => const QuestionBankScreen(),
          ),
          GoRoute(
            path: '/question-bank/detail/:id',
            builder: (context, state) => QuestionDetailScreen(
              questionId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/ai-test',
            builder: (context, state) => const TestBuilderScreen(),
          ),
          GoRoute(
            path: '/performance',
            builder: (context, state) => const PerformanceScreen(),
          ),
          GoRoute(
            path: '/revision',
            builder: (context, state) => const RevisionScreen(),
          ),
          GoRoute(
            path: '/mistakes',
            builder: (context, state) => const MistakesScreen(),
          ),
          GoRoute(
            path: '/flashcards',
            builder: (context, state) => const FlashcardsScreen(),
          ),
          GoRoute(
            path: '/formula-bank',
            builder: (context, state) => const FormulaBankScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

