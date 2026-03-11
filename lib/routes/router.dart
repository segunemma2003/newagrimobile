import '/resources/pages/not_found_page.dart';
import '/resources/pages/intro_page.dart';
import '/resources/pages/login_page.dart';
import '/resources/pages/register_page.dart';
import '/resources/pages/welcome_page.dart';
import '/resources/pages/main_navigation_page.dart';
import '/resources/pages/course_detail_page.dart';
import '/resources/pages/lesson_detail_page.dart';
import '/resources/pages/quiz_page.dart';
import '/resources/pages/notes_page.dart';
import '/resources/pages/modules_overview_page.dart';
import '/resources/pages/assignment_page.dart';
import '/resources/pages/profile_page.dart';
import '/resources/pages/messages_page.dart';
import '/resources/pages/edit_profile_page.dart';
import '/resources/pages/certificates_page.dart';
import '/resources/pages/community_forum_page.dart';
import '/resources/pages/forum_post_detail_page.dart';
import '/resources/pages/chat_detail_page.dart';
import '/resources/pages/change_password_page.dart';
import '/resources/pages/forgot_password_page.dart';
import '/resources/pages/reset_password_page.dart';
import '/resources/pages/help_support_page.dart';
import '/resources/pages/terms_conditions_page.dart';
import '/resources/pages/notification_settings_page.dart';
import '/resources/pages/notifications_page.dart';
import '/resources/pages/language_settings_page.dart';
import '/resources/pages/contact_admin_page.dart';
import '/routes/guards/auth_route_guard.dart';
import 'package:nylo_framework/nylo_framework.dart';

/* App Router
|--------------------------------------------------------------------------
| * [Tip] Create pages faster 🚀
| Run the below in the terminal to create new a page.
| "dart run nylo_framework:main make:page profile_page"
|
| * [Tip] Add authentication 🔑
| Run the below in the terminal to add authentication to your project.
| "dart run scaffold_ui:main auth"
|
| * [Tip] Add In-app Purchases 💳
| Run the below in the terminal to add In-app Purchases to your project.
| "dart run scaffold_ui:main iap"
|
| Learn with Agrisiti - Application Router
|-------------------------------------------------------------------------- */

appRouter() => nyRoutes((router) {
      print('ROUTER: Setting WelcomePage as initial route');
      router
          .add(WelcomePage.path)
          .initialRoute(); // TEMP: Test if WelcomePage works
      print('ROUTER: WelcomePage path = ${WelcomePage.path}');
      router.add(IntroPage.path);
      router.add(LoginPage.path);
      router.add(RegisterPage.path);
      router.add(ForgotPasswordPage.path);
      router.add(ResetPasswordPage.path);

      // Protected routes
      router.group(
          () => {
                "route_guards": [AuthRouteGuard()],
              }, (router) {
        router.add(MainNavigationPage.path);
        // Detail pages that should be navigated to from main nav
        router.add(CourseDetailPage.path);
        router.add(LessonDetailPage.path);
        router.add(QuizPage.path);
        router.add(NotesPage.path);
        router.add(ModulesOverviewPage.path);
        router.add(AssignmentPage.path);
        router.add(ProfilePage.path);
        router.add(MessagesPage.path);
        router.add(EditProfilePage.path);
        router.add(CertificatesPage.path);
        router.add(CommunityForumPage.path);
        router.add(ForumPostDetailPage.path);
        router.add(ChatDetailPage.path);
        router.add(ChangePasswordPage.path);
        router.add(HelpSupportPage.path);
        router.add(TermsConditionsPage.path);
        router.add(NotificationSettingsPage.path);
        router.add(NotificationsPage.path);
        router.add(LanguageSettingsPage.path);
        router.add(ContactAdminPage.path);
      });

      router.add(NotFoundPage.path).unknownRoute();
    });
