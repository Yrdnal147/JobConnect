import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'presentation/pages/shared/splash_page.dart';
import 'presentation/pages/shared/onboarding_page.dart';
import 'presentation/pages/shared/status_selection_page.dart';
import 'presentation/pages/shared/register_page.dart';
import 'presentation/pages/shared/login_page.dart';
import 'presentation/pages/shared/audio_call_page.dart';
import 'presentation/pages/shared/video_call_page.dart';
import 'presentation/pages/student/home/notifications_page.dart';
import 'presentation/blocs/notifications/notification_cubit.dart';
import 'injection_container.dart';
import 'presentation/pages/student/student_shell.dart';
import 'presentation/pages/student/home/home_page.dart';
import 'presentation/pages/student/search/search_page.dart';
import 'presentation/pages/student/applications/applications_page.dart';
import 'presentation/pages/student/messaging/conversations_page.dart';
import 'presentation/pages/student/profile/profile_page.dart';
import 'presentation/pages/student/success/success_page.dart';
import 'presentation/pages/company/company_shell.dart';
import 'presentation/pages/company/dashboard/dashboard_page.dart';
import 'presentation/pages/company/offers/my_offers_page.dart';
import 'presentation/pages/company/offers/active_offer_page.dart';
import 'presentation/pages/company/offers/create_offer_page.dart';
import 'presentation/pages/company/offers/offer_detail_page.dart';
import 'presentation/pages/company/candidates/candidates_page.dart';
import 'presentation/pages/company/profile/company_profile_page.dart';
import 'presentation/pages/company/messaging/conversations_page.dart';
import 'presentation/pages/student/offer/offer_detail_page.dart';
import 'presentation/pages/student/applications/application_detail_page.dart';
import 'presentation/pages/student/messaging/chat_page.dart';
import 'presentation/pages/company/candidates/candidate_detail_page.dart';
import 'presentation/pages/company/candidates/retained_candidates_page.dart';
import 'presentation/pages/company/candidates/all_candidates_page.dart';
import 'presentation/pages/company/messaging/chat_page.dart';
import 'presentation/pages/company/profile/company_verification_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Pages partagées ────────────────────────────────────────────────────
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/status-selection',
      builder: (context, state) => const StatusSelectionPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return RegisterPage(role: extra['role'] as String);
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final name = extra['name'] as String? ?? 'Inconnu';
        final photoUrl = extra['photoUrl'] as String?;
        final subtitle = extra['subtitle'] as String?;
        final jobDetails = extra['jobDetails'] as List<String>? ?? const [];

        return AudioCallPage(
          name: name,
          photoUrl: photoUrl,
          subtitle: subtitle,
          jobDetails: jobDetails,
        );
      },
    ),
    GoRoute(
      path: '/video-call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final name = extra['name'] as String? ?? 'Inconnu';
        final photoUrl = extra['photoUrl'] as String?;
        final subtitle = extra['subtitle'] as String?;
        final jobDetails = extra['jobDetails'] as List<String>? ?? const [];

        return VideoCallPage(
          name: name,
          photoUrl: photoUrl,
          subtitle: subtitle,
          jobDetails: jobDetails,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => BlocProvider<NotificationCubit>(
        create: (_) => sl<NotificationCubit>()..loadNotifications(),
        child: const NotificationsPage(),
      ),
    ),

    // ── Pages student secondaires (hors shell) ─────────────────────────────
    GoRoute(
      path: '/student/success',
      builder: (context, state) => const SuccessPage(),
    ),
    GoRoute(
      path: '/student/applications/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ApplicationDetailPage(applicationId: id);
      },
    ),
    GoRoute(
      path: '/student/messages/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ChatPage(conversationId: id);
      },
    ),
    GoRoute(
      path: '/student/offer/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? ''; // ← fix : était nullable
        return OfferDetailPage(offerId: id);
      },
    ),

    // ── Pages company secondaires (hors shell) ─────────────────────────────
    GoRoute(
      path: '/company/success',
      builder: (context, state) => const SuccessPage(),
    ),
    GoRoute(
      path: '/company/offers/active',
      builder: (context, state) => const ActiveOffersPage(),
    ),
    GoRoute(
      path: '/company/offers/create',
      builder: (context, state) => const CreateOfferPage(),
    ),
    GoRoute(
      path: '/company/offers/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CompanyOfferDetailPage(offerId: id);
      },
    ),
    GoRoute(
      path: '/company/candidates/retained',
      builder: (context, state) => const RetainedCandidatesPage(),
    ),
    GoRoute(
      path: '/company/candidates/all',
      builder: (context, state) => const AllCandidatesPage(),
    ),
    GoRoute(
      path: '/company/candidates/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CandidateDetailPage(applicationId: id);
      },
    ),
    GoRoute(
      path: '/company/messages/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CompanyChatPage(conversationId: id);
      },
    ),
    GoRoute(
      path: '/company/profile/verify',
      builder: (context, state) => const CompanyVerificationPage(),
    ),

    // ── Student shell ──────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => StudentShell(child: child),
      routes: [
        GoRoute(
          path: '/student/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/student/search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/student/applications',
          builder: (context, state) => const ApplicationsPage(),
        ),
        GoRoute(
          path: '/student/messages',
          builder: (context, state) => const ConversationsPage(),
        ),
        GoRoute(
          path: '/student/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),

    // ── Company shell ───────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => CompanyShell(child: child),
      routes: [
        GoRoute(
          path: '/company/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/company/offers',
          builder: (context, state) => const MyOffersPage(),
        ),
        GoRoute(
          path: '/company/candidates',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CandidatesPage(offer: extra);
          },
        ),
        GoRoute(
          path: '/company/messages',
          builder: (context, state) => const CompanyConversationsPage(),
        ),
        GoRoute(
          path: '/company/profile',
          builder: (context, state) => const CompanyProfilePage(),
        ),
      ],
    ),
  ],
);
