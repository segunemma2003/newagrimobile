import '/resources/pages/login_page.dart';
import '/config/keys.dart';
import '/app/helpers/storage_helper.dart';
import 'package:nylo_framework/nylo_framework.dart';

/* Auth Route Guard
|--------------------------------------------------------------------------
| Checks if the User is authenticated.
|
| * [Tip] Create new route guards using the CLI 🚀
| Run the below in the terminal to create a new route guard.
| "dart run nylo_framework:main make:route_guard check_subscription"
|
| Learn with Agrisiti - Route Guards
|-------------------------------------------------------------------------- */

class AuthRouteGuard extends NyRouteGuard {
  AuthRouteGuard();

  @override
  onRequest(PageRequest pageRequest) async {
    // Check authentication from local storage (works offline)
    // Auth.isAuthenticated() checks if Keys.auth has a value stored locally
    // This does NOT require internet connection
    try {
      bool isLoggedIn = (await Auth.isAuthenticated());
      if (!isLoggedIn) {
        // Also check Backpack (session storage) as fallback
        var backpackAuth = safeReadAuthData();
        if (backpackAuth == null || backpackAuth.isEmpty) {
          return redirect(LoginPage.path);
        }
        // Also verify token exists
        final token = await Keys.bearerToken.read<String>();
        if (token == null || token.isEmpty) {
          return redirect(LoginPage.path);
        }
      } else {
        // Verify auth data is valid and token exists
        final authData = safeReadAuthData();
        if (authData == null || authData.isEmpty) {
          return redirect(LoginPage.path);
        }
        final token = await Keys.bearerToken.read<String>();
        if (token == null || token.isEmpty) {
          return redirect(LoginPage.path);
        }
      }
    } catch (e) {
      // Handle storage errors gracefully - check Backpack as fallback
      // Suppress error logging for Keychain issues on simulator
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to check authentication from storage: $e');
      }
      var backpackAuth = safeReadAuthData();
      if (backpackAuth == null || backpackAuth.isEmpty) {
        return redirect(LoginPage.path);
      }
      // Verify token exists
      try {
        final token = await Keys.bearerToken.read<String>();
        if (token == null || token.isEmpty) {
          return redirect(LoginPage.path);
        }
      } catch (e2) {
        return redirect(LoginPage.path);
      }
    }

    return pageRequest;
  }
}
