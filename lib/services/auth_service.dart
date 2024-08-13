import 'package:nzinga/cores/locator/locator.dart';
import 'package:nzinga/view_models/home/home_viewmodel.dart';
import 'package:nzinga/views/auth/login/login_screen.dart';
import 'package:nzinga/views/auth/verify/verify.dart';
import 'package:nzinga/views/home/home_sreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      await _supabaseClient.auth.signUp(email: email, password: password);


      snackbarService.success(message: 'Account Created Successfully');
      navigationService.pushAndRemoveUntil(const VerifyScreen());
    } on AuthException catch (authError) {
      snackbarService.error(message: authError.message);
    } catch (error) {
      snackbarService.error(message: error.toString());
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      final AuthResponse res = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      bool isVerified = await checkUser();
      if(isVerified == true){
        String token = res.session!.accessToken;
        snackbarService.success(message: 'Sign In Successful');
        await HomeViewModel.saveTokenGlobally(token);
        navigationService.pushAndRemoveUntil(const HomeScreen());
      }
      else {
        snackbarService.error(message: 'A link has been sent to your mail for email verification');
      }

    } on AuthException catch (authError) {
      snackbarService.error(message: authError.message);
    } catch (error) {
      snackbarService.error(message: error.toString());
    }
  }

  Future<bool> checkUser() async {
    bool result = false;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      if (user.emailConfirmedAt != null) {
        result = true;
        print('Email is verified');
      } else {
        result = false;
      //  await resendLink();
        print('Email is not verified');
      }
    }
    return result;
  }


  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> checkAuthenticationStatus() async {
  String? token = await loadToken();
  if (token != null) {
    navigationService.pushAndRemoveUntil(const HomeScreen());
    return true; // Return true indicating authenticated
  } else {
    navigationService.pushAndRemoveUntil(const LoginScreen());
    return false;
  }
}

resendLink() async{
  try{
    await Supabase.instance.client.auth.resend(type: OtpType.email);
  }catch(e){
    print(e.toString());
  }
}


}
