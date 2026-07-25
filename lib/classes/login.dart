import 'package:flutter/material.dart';
import '../classes/classes.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../screens/screens.dart';
import '../constants.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class Login extends StatelessWidget {
  BuildContext context;
  Login({super.key, required this.context});
  @override
  build(BuildContext context) {
    return Text('T');
  }

  Future<bool> tryLoggingIn() async {
    try {
      ///  User user = await getUser();
      /// Three possibilities for logging in
      /// 1 Password & email on device
      ///   Silent login retrieving fresh jwt
      /// 2 No password or email on device - new device / user
      ///   Login dialog appears
      /// 3 Email on device and password < 8 characters
      ///   Sign_up form appears to allow completion of registration
      //   int code = 0;

      //   if (Setup().isWeb) {
      //     return true;
      //   }

      if ((!kIsWeb && Setup().user.password.isEmpty) ||
          (kIsWeb && Setup().jwt.isNotEmpty)) {
        await getPrivateRepository().getUser();
      }

      LoginState loginState = LoginState.notLoggedin;
      Setup().serverUp = await serverListening();
      if (Setup().serverUp) {
        /// Try silent login first
        if (Setup().jwt.isNotEmpty &&
            Setup().user.email.isNotEmpty &&
            Setup().user.password.length > 8) {
          bool refreshed = await refreshToken();
          if (refreshed) {
            Setup().hasLoggedIn = true;
            return true;
          }
        }

        if (Setup().user.email.isNotEmpty && Setup().user.password.length > 8) {
          Map<String, dynamic> response = await tryLogin(user: Setup().user);
          String status = response['msg'] ?? '';
          //    code = response['response_status_code'] ?? 0;

          if (status == 'OK') {
            await getPrivateRepository().saveUser(Setup().user);
            Setup().hasLoggedIn = true;
            return status == 'OK';
          }

          /// Have user details on device but not on server
          loginState = LoginState.register;
        }

        /// Device has no login details invite user to login
        User user = Setup().user;
        if ((Setup().user.email.isEmpty ||
                Setup().jwt.isEmpty ||
                Setup().user.password.isEmpty) &&
            context.mounted) {
          loginState = await loginDialog(context, user: user);

          if (loginState == LoginState.login) {
            Map<String, dynamic> response = await tryLogin(user: user);
            if (response['msg'] == 'OK') {
              Setup().hasLoggedIn = true;
              await getPrivateRepository().saveUser(user);
              Setup().user = user;
              return true;
            }
            // return false;
          } else if (loginState == LoginState.cancel) {
            return false;
          }
        }

        /// Handle partially loggedin users invite to complete registration
        if ([
          LoginState.register,
          LoginState.notLoggedin,
          LoginState.resetPassword
        ].contains(loginState)) {
          if (user.password.length != 6) {
            await postValidateUser(user: user);
            Setup().user = user;
            Setup().user.password = '';
          }
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const SignupForm()),
            );
          }
        }

        /// Now handle login failures
        ///       New user both email and password empty  register
        /// 401 - Invalid password                        login dialog
        /// 410 - Missing password                        register
        /// 204 - Email not found                         register

        Setup().hasLoggedIn = true;
        return true; //critical one
      } else {
        debugPrint('Server not listening ($urlBase)');
        return false;
      }
      // return false;
    } catch (e) {
      debugPrint('Splash login error: ${e.toString()}');
      return false;
    }
  }
}
