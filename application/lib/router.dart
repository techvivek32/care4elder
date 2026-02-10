import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/selection/screens/user_selection_screen.dart';
import 'features/patient/screens/patient_login_screen.dart';
import 'features/patient/screens/patient_signup_screen.dart';
import 'features/patient/screens/patient_otp_screen.dart';
import 'features/patient/screens/patient_permissions_screen.dart';
import 'features/patient/screens/patient_emergency_contacts_screen.dart';
import 'features/patient/screens/patient_relative_otp_screen.dart';
import 'features/patient/screens/patient_dashboard_screen.dart';
import 'features/patient/screens/patient_shell.dart';
import 'features/doctor_auth/screens/doctor_login_screen.dart';
import 'features/doctor_auth/screens/doctor_otp_screen.dart';
import 'features/doctor_auth/screens/doctor_signup_screen.dart';
import 'features/doctor_auth/screens/doctor_registration_screen.dart';
import 'features/doctor_auth/screens/doctor_registration_summary_screen.dart';
import 'features/doctor_auth/screens/doctor_verification_pending_screen.dart';
import 'features/doctor_auth/screens/doctor_rejected_screen.dart';
import 'features/doctor_dashboard/screens/doctor_shell.dart';
import 'features/doctor_dashboard/screens/doctor_home_screen.dart';
import 'features/doctor_dashboard/screens/doctor_requests_screen.dart';
import 'features/doctor_dashboard/screens/doctor_records_screen.dart';
import 'features/doctor_dashboard/screens/doctor_request_details_screen.dart';
import 'features/doctor_dashboard/screens/doctor_call_screen.dart';
import 'features/doctor_dashboard/screens/doctor_call_summary_screen.dart';
import 'features/consultation/screens/consultation_screen.dart';
import 'features/consultation/screens/doctor_profile_screen.dart';
import 'features/emergency/screens/sos_screen.dart';
import 'features/records/screens/medical_records_screen.dart';
import 'features/profile/screens/patient_profile_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/call/screens/video_call_screen.dart';
import 'features/call/screens/patient_ringing_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/settings/screens/app_settings_screen.dart';
import 'features/profile/screens/patient_wallet_screen.dart';
import 'features/doctor_dashboard/screens/doctor_history_screen.dart';
import 'features/doctor_dashboard/screens/doctor_profile_tab_screen.dart';
import 'features/doctor_dashboard/screens/doctor_settings_screen.dart';
import 'features/doctor_dashboard/screens/doctor_availability_screen.dart';
import 'features/doctor_dashboard/screens/doctor_edit_profile_screen.dart';
import 'features/doctor_dashboard/screens/doctor_earnings_screen.dart';
import 'features/doctor_dashboard/screens/doctor_consultation_fee_screen.dart';
import 'features/doctor_dashboard/screens/doctor_change_password_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/selection',
      builder: (context, state) => const UserSelectionScreen(),
    ),
    GoRoute(
      path: '/patient',
      builder: (context, state) => const PatientLoginScreen(),
    ),
    GoRoute(
      path: '/patient/signup',
      builder: (context, state) => const PatientSignupScreen(),
    ),
    GoRoute(
      path: '/patient/otp',
      builder: (context, state) {
        final extra = state.extra;
        String phone = '';
        String? email;
        Map<String, dynamic>? signupData;
        bool isSignup = false;

        if (extra is String) {
          phone = extra;
        } else if (extra is Map<String, dynamic>) {
          phone = extra['phone'] ?? '';
          email = extra['email'];
          isSignup = extra['isSignup'] ?? false;
          signupData = extra['data'];
        }

        return PatientOtpScreen(
          phoneNumber: phone,
          email: email,
          isSignup: isSignup,
          signupData: signupData,
        );
      },
    ),
    GoRoute(
      path: '/patient/permissions',
      builder: (context, state) => const PatientPermissionsScreen(),
    ),
    GoRoute(
      path: '/patient/contacts',
      builder: (context, state) => const PatientEmergencyContactsScreen(),
    ),
    GoRoute(
      path: '/patient/contacts/otp',
      builder: (context, state) {
        final phone = state.extra as String;
        return PatientRelativeOtpScreen(phoneNumber: phone);
      },
    ),
    // Doctor Auth Routes
    GoRoute(
      path: '/doctor/login',
      builder: (context, state) => const DoctorLoginScreen(),
    ),
    GoRoute(
      path: '/doctor/signup',
      builder: (context, state) => const DoctorSignupScreen(),
    ),
    GoRoute(
      path: '/doctor/otp',
      builder: (context, state) {
        final extra = state.extra;
        String identifier = '';
        bool isEmail = false;
        bool isLogin = false;

        if (extra is String) {
          identifier = extra;
        } else if (extra is Map<String, dynamic>) {
          identifier = extra['identifier'] ?? '';
          isEmail = extra['isEmail'] ?? false;
          isLogin = extra['isLogin'] ?? false;
        }

        return DoctorOtpScreen(
          identifier: identifier,
          isEmail: isEmail,
          isLogin: isLogin,
        );
      },
    ),
    GoRoute(
      path: '/doctor/register-form',
      builder: (context, state) => const DoctorRegistrationScreen(),
    ),
    GoRoute(
      path: '/doctor/summary',
      builder: (context, state) => const DoctorRegistrationSummaryScreen(),
    ),
    GoRoute(
      path: '/doctor/verification-pending',
      builder: (context, state) => const DoctorVerificationPendingScreen(),
    ),
    GoRoute(
      path: '/doctor/rejected',
      builder: (context, state) => const DoctorRejectedScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return DoctorShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/doctor/home',
          builder: (context, state) => const DoctorHomeScreen(),
        ),
        GoRoute(
          path: '/doctor/requests',
          builder: (context, state) => const DoctorRequestsScreen(),
        ),
        GoRoute(
          path: '/doctor/records',
          builder: (context, state) => const DoctorRecordsScreen(),
        ),
        GoRoute(
          path: '/doctor/history',
          builder: (context, state) => const DoctorHistoryScreen(),
        ),
        GoRoute(
          path: '/doctor/profile',
          builder: (context, state) => const DoctorProfileTabScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const DoctorEditProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/doctor/settings',
      builder: (context, state) => const DoctorSettingsScreen(),
      routes: [
        GoRoute(
          path: 'availability',
          builder: (context, state) => const DoctorAvailabilityScreen(),
        ),
        GoRoute(
          path: 'consultation-fee',
          builder: (context, state) => const DoctorConsultationFeeScreen(),
        ),
        GoRoute(
          path: 'change-password',
          builder: (context, state) => const DoctorChangePasswordScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/doctor/request-details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final extra = state.extra;
        Map<String, String>? requestData;
        if (extra is Map<String, String>) {
          requestData = extra;
        } else if (extra is Map<String, dynamic>) {
          requestData = extra.map((key, value) {
            return MapEntry(key, value?.toString() ?? '');
          });
        }
        return DoctorRequestDetailsScreen(
          requestId: id,
          requestData: requestData,
        );
      },
    ),
    GoRoute(
      path: '/doctor/call/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DoctorCallScreen(patientId: id);
      },
    ),
    GoRoute(
      path: '/doctor/call-summary/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DoctorCallSummaryScreen(patientId: id);
      },
    ),
    GoRoute(
      path: '/doctor/call-room',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final channel = extra?['channel'] ?? '';
        final remoteName = extra?['remoteName'] ?? 'Patient';
        final callRequestId = extra?['callRequestId'];
        return VideoCallScreen(
          channelName: channel,
          remoteUserName: remoteName,
          callRequestId: callRequestId,
          isDoctor: true,
        );
      },
    ),
    GoRoute(
      path: '/doctor/earnings',
      builder: (context, state) => const DoctorEarningsScreen(),
    ),
    GoRoute(
      path: '/doctor/notifications',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return PatientShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/patient/dashboard',
          builder: (context, state) => const PatientDashboardScreen(),
        ),
        GoRoute(
          path: '/patient/consultation',
          builder: (context, state) => const ConsultationScreen(),
        ),
        GoRoute(
          path: '/patient/sos',
          builder: (context, state) {
            final autoStart = state.uri.queryParameters['autoStart'] == 'true';
            return SosScreen(autoStart: autoStart);
          },
        ),
        GoRoute(
          path: '/patient/doctor/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DoctorProfileScreen(doctorId: id);
          },
        ),
        GoRoute(
          path: '/patient/records',
          builder: (context, state) => const MedicalRecordsScreen(),
        ),
        GoRoute(
          path: '/patient/profile',
          builder: (context, state) => const PatientProfileScreen(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, state) => const AppSettingsScreen(),
            ),
            GoRoute(
              path: 'wallet',
              builder: (context, state) => const PatientWalletScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/patient/profile/personal-info',
          builder: (context, state) => const PersonalInfoScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/patient/doctor/:id/call',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final name = extra?['doctorName'] ?? 'Doctor';
        final callRequestId = extra?['callRequestId'];
        return VideoCallScreen(
          channelName: id,
          remoteUserName: name,
          callRequestId: callRequestId,
          isDoctor: false,
        );
      },
    ),
    GoRoute(
      path: '/patient/doctor/:id/ringing',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PatientRingingScreen(
          callRequestId: extra['callRequestId'] ?? '',
          channelName: extra['channelName'] ?? '',
          doctorName: extra['doctorName'] ?? 'Doctor',
        );
      },
    ),
    GoRoute(
      path: '/patient/notifications',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    ),
  ],
);
