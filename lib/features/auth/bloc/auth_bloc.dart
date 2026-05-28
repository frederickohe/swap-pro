import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:swappro/config/app_config.dart';
import 'package:swappro/common_bloc/success_bloc.dart';
import 'package:swappro/services/backend_connectivity.dart';
import 'package:swappro/utils/phone_utils.dart';
import '../models/token_model.dart';
import '../services/token_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final TokenService tokenService;
  final SuccessBloc successBloc;

  /// Kept briefly after signup so OTP verification can refresh the auth session.
  String? _pendingSignupEmail;
  String? _pendingSignupPassword;

  AuthBloc({TokenService? tokenService, SuccessBloc? successBloc})
    : tokenService = tokenService ?? TokenService(),
      successBloc = successBloc ?? SuccessBloc(),
      super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<SignupEvent>(_onSignup);
    on<CheckAuthEvent>(_onCheckAuth);
    on<LogoutEvent>(_onLogout);
    on<VerifyResetCodeEvent>(_onVerifyResetCode);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckEmailExistsEvent>(_onCheckEmailExists);
    on<SendResetCodeEvent>(_onSendResetCode);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<CheckSessionEvent>(_onCheckSession);
    on<VerifySignupOtpEvent>(_onVerifySignupOtp);
    on<ResendSignupOtpEvent>(_onResendSignupOtp);
  }

  String _messageFromResponse(http.Response response, String fallback) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is! Map) return fallback;
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
      }
      final message = decoded['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    } catch (_) {}
    return fallback;
  }

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final accessToken = await tokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': event.email,
          'email': event.email,
          'password': event.password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse and save token
        final tokenModel = TokenModel.fromJson(data);
        await tokenService.saveToken(tokenModel);

        // Fetch user data using access token
        final userResponse = await http.get(
          Uri.parse('${AppConfig.backendUrl}/api/v1/user/me'),
          headers: await _getAuthHeaders(),
        );

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(userData));
          emit(Authenticated(user: userData));
        } else {
          String errorMsg = 'Failed to fetch user data';
          try {
            final errorData = json.decode(userResponse.body);
            if (errorData is Map && errorData['detail'] != null) {
              errorMsg = errorData['detail'];
            }
          } catch (_) {}
          print('User fetch error: ${userResponse.body}');
          emit(AuthError(message: errorMsg, source: 'login'));
        }
      } else {
        String errorMsg = 'Login failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'].toString();
          }
        } catch (_) {}
        if (errorMsg.toLowerCase().contains('invalid username and password')) {
          errorMsg = 'Invalid email/username or PIN';
        }
        emit(AuthError(message: errorMsg, source: 'login'));
      }
    } catch (e) {
      if (BackendConnectivity.isNetworkFailure(e)) {
        emit(const ServerUnreachable());
        return;
      }
      emit(AuthError(message: e.toString(), source: 'login'));
    }
  }

  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // Backend DTO expects `fullname` (we collect it as username in UI).
          'fullname': event.username,
          'phone': normalizePhone(event.phone),
          'email': event.email,
          'password': event.password,
          'company': event.company,
          'ghana_card': event.ghanaCard,
        }),
      );

      if (response.statusCode == 200) {
        _pendingSignupEmail = event.email;
        _pendingSignupPassword = event.password;

        // Auto-login after signup so a token is available for OTP verification.
        final loginResponse = await http.post(
          Uri.parse('${AppConfig.backendUrl}/api/v1/auth/signin'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': event.email, 'password': event.password}),
        );

        if (loginResponse.statusCode == 200) {
          final tokenData = json.decode(loginResponse.body);
          final tokenModel = TokenModel.fromJson(tokenData);
          await tokenService.saveToken(tokenModel);
        }
        // Emit Registered even if auto-login fails (user can sign in manually).
        emit(
          Registered(
            email: event.email,
            message: 'Account creation was successful!',
          ),
        );
      } else {
        String errorMsg = 'Signup failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(AuthError(message: errorMsg, source: 'signup'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString(), source: 'signup'));
    }
  }

  Future<void> _onVerifySignupOtp(
    VerifySignupOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final phone = normalizePhone(event.phone);
    final otp = event.otp.trim();

    if (phone.isEmpty) {
      emit(const AuthError(
        message: 'Phone number is missing. Go back and sign up again.',
        source: 'signup_otp',
      ));
      return;
    }
    if (otp.length != 5) {
      emit(const AuthError(
        message: 'Enter the 5-digit code from your SMS.',
        source: 'signup_otp',
      ));
      return;
    }

    try {
      final uri = Uri.parse('${AppConfig.backendUrl}/api/v1/auth/verify-otp');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == false) {
          emit(AuthError(
            message: data['message']?.toString() ?? 'OTP verification failed',
            source: 'signup_otp',
          ));
          return;
        }
        await _refreshSignupSession();
        emit(
          SignupOtpVerified(
            phone: phone,
            message: (data is Map && data['message'] != null)
                ? data['message'].toString()
                : 'OTP verified successfully',
          ),
        );
      } else {
        emit(AuthError(
          message: _messageFromResponse(
            response,
            'OTP verification failed (${response.statusCode})',
          ),
          source: 'signup_otp',
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Could not reach the server. Check your connection and try again.',
        source: 'signup_otp',
      ));
    }
  }

  Future<void> _onResendSignupOtp(
    ResendSignupOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final phone = normalizePhone(event.phone);
    if (phone.isEmpty) {
      emit(const AuthError(
        message: 'Phone number is missing.',
        source: 'signup_otp_resend',
      ));
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        emit(
          SignupOtpResent(
            phone: event.phone,
            message: (data is Map && data['message'] != null)
                ? data['message'].toString()
                : 'OTP resent successfully',
          ),
        );
      } else {
        String errorMsg = 'Failed to resend OTP';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(AuthError(message: errorMsg, source: 'signup_otp_resend'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString(), source: 'signup_otp_resend'));
    }
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    add(const CheckSessionEvent());
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await tokenService.clearTokens();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: $e', source: 'logout'));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/auth/no-auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': event.email,
          'new_password': event.newPassword,
        }),
      );

      if (response.statusCode == 200) {
        emit(PasswordResetSuccess(message: 'Password reset successfully'));
      } else {
        String errorMsg = 'Password reset failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(AuthError(message: errorMsg, source: 'reset_password'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString(), source: 'reset_password'));
    }
  }

  Future<void> _onCheckEmailExists(
    CheckEmailExistsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/auth/verify-account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': event.email}),
      );

      if (response.statusCode == 200) {
        emit(EmailExists(email: event.email));
      } else {
        String errorMsg = 'Email check failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(AuthError(message: errorMsg, source: 'check_email'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString(), source: 'check_email'));
    }
  }

  //////////////   OTP Code Handers //////////////////////

  Future<void> _onSendResetCode(
    SendResetCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': event.email, 'phone': event.phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        emit(
          ResetCodeSent(
            email: event.email,
            message: data['message'] ?? 'Reset code sent successfully',
          ),
        );
      } else {
        String errorMsg = 'Failed to send reset code';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(AuthError(message: errorMsg, source: 'send_reset_code'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString(), source: 'send_reset_code'));
    }
  }

  Future<void> _onVerifyResetCode(
    VerifyResetCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': event.email,
          'phone': event.phone,
          'otp': event.code,
        }),
      );

      if (response.statusCode == 200) {
        emit(ResetCodeVerified(email: event.email, code: event.code));
      } else {
        String errorMsg = 'Invalid verification code';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(AuthError(message: errorMsg, source: 'verify_code'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString(), source: 'verify_code'));
    }
  }

  Future<void> _refreshSignupSession() async {
    final email = _pendingSignupEmail;
    final password = _pendingSignupPassword;
    if (email == null || password == null) return;

    try {
      final loginResponse = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (loginResponse.statusCode == 200) {
        final tokenModel = TokenModel.fromJson(json.decode(loginResponse.body));
        await tokenService.saveToken(tokenModel);

        final userResponse = await http.get(
          Uri.parse('${AppConfig.backendUrl}/api/v1/user/me'),
          headers: await _getAuthHeaders(),
        );
        if (userResponse.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(json.decode(userResponse.body)));
        }
      }
    } catch (_) {
      // OTP succeeded; user can sign in manually if session refresh fails.
    } finally {
      _pendingSignupEmail = null;
      _pendingSignupPassword = null;
    }
  }

  // Token Refresh Handler
  Future<void> _onRefreshToken(
    RefreshTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(TokenRefreshing());
    try {
      final refreshToken =
          event.refreshToken ?? await tokenService.getRefreshToken();

      if (refreshToken == null) {
        emit(SessionExpired());
        return;
      }

      final response = await http
          .post(
            Uri.parse('${AppConfig.backendUrl}/api/v1/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newTokenModel = TokenModel.fromJson(data);

        // Save new tokens
        await tokenService.updateToken(newTokenModel);

        // Fetch updated user data
        final userResponse = await http
            .get(
              Uri.parse('${AppConfig.backendUrl}/api/v1/user/me'),
              headers: await _getAuthHeaders(),
            )
            .timeout(const Duration(seconds: 15));

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(userData));
          emit(Authenticated(user: userData));
        } else {
          emit(
            TokenRefreshFailed(
              message: 'Failed to fetch user data after token refresh',
            ),
          );
        }
      } else if (response.statusCode == 401) {
        // Refresh token is invalid or expired
        await tokenService.clearTokens();
        emit(
          SessionExpired(
            message: 'Your session has expired. Please login again.',
          ),
        );
      } else {
        String errorMsg = 'Failed to refresh token';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        emit(TokenRefreshFailed(message: errorMsg));
      }
    } catch (e) {
      if (BackendConnectivity.isNetworkFailure(e)) {
        emit(const ServerUnreachable());
        return;
      }
      emit(TokenRefreshFailed(message: 'Token refresh error: $e'));
    }
  }

  Future<bool> _restoreUserProfile(Emitter<AuthState> emit) async {
    final userResponse = await http
        .get(
          Uri.parse('${AppConfig.backendUrl}/api/v1/user/me'),
          headers: await _getAuthHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    if (userResponse.statusCode == 200) {
      final userData = json.decode(userResponse.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(userData));
      emit(Authenticated(user: userData));
      return true;
    }

    if (userResponse.statusCode == 401) {
      add(const RefreshTokenEvent());
      return true;
    }

    return false;
  }

  // Session Check Handler
  Future<void> _onCheckSession(
    CheckSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final reachable = await BackendConnectivity.isReachable();
      if (!reachable) {
        emit(const ServerUnreachable());
        return;
      }

      final token = await tokenService.getToken();
      if (token == null) {
        emit(const Unauthenticated());
        return;
      }

      if (token.isExpired) {
        final refreshToken = await tokenService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          add(const RefreshTokenEvent());
          return;
        }
        await tokenService.clearTokens();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user');
        emit(const Unauthenticated());
        return;
      }

      if (await tokenService.shouldRefreshToken()) {
        add(const RefreshTokenEvent());
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        emit(Authenticated(user: json.decode(userString)));
        return;
      }

      final restored = await _restoreUserProfile(emit);
      if (!restored) {
        emit(const Unauthenticated());
      }
    } catch (e) {
      if (BackendConnectivity.isNetworkFailure(e)) {
        emit(const ServerUnreachable());
        return;
      }
      emit(
        AuthError(message: 'Session check failed: $e', source: 'check_session'),
      );
    }
  }
}
