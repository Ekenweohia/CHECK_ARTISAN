import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:check_artisan/RegistrationArtisan/login_artisan.dart';
import 'package:check_artisan/VerificationArtisan/otp_verificationartisan.dart';
import 'package:check_artisan/page_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class RegisterSubmitted extends AuthEvent {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String password;

  const RegisterSubmitted({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object> get props => [firstName, lastName, phoneNumber, password];
}

class GoogleLogin extends AuthEvent {}

class FacebookLogin extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object> get props => [error];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final bool useApi;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthBloc({this.useApi = false}) : super(AuthInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<GoogleLogin>(_onGoogleLogin);
    on<FacebookLogin>(_onFacebookLogin);
  }

  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      if (useApi) {
        final response = await http.post(
          Uri.parse(''), // API URL for registration
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'firstName': event.firstName,
            'lastName': event.lastName,
            'phoneNumber': event.phoneNumber,
            'password': event.password,
          }),
        );

        if (response.statusCode == 200) {
          emit(AuthSuccess());
        } else {
          final error = jsonDecode(response.body)['error'];
          emit(AuthFailure(error));
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        emit(AuthSuccess());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleLogin(
      GoogleLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        emit(AuthSuccess());
      } else {
        emit(const AuthFailure('Google sign-in was cancelled.'));
      }
    } catch (e) {
      emit(AuthFailure('Google sign-in failed: $e'));
    }
  }

  Future<void> _onFacebookLogin(
      FacebookLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure('Facebook sign-in failed: ${result.message}'));
      }
    } catch (e) {
      emit(AuthFailure('Facebook sign-in failed: $e'));
    }
  }
}

class PhoneArtisan extends StatefulWidget {
  const PhoneArtisan({Key? key}) : super(key: key);

  @override
  PhoneArtisanState createState() => PhoneArtisanState();
}

class PhoneArtisanState extends State<PhoneArtisan> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/reg screen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: const Color(0xF2004D40),
          ),
          Column(
            children: [
              const SizedBox(height: 80),
              Center(
                child: Image.asset(
                  'assets/icons/logo checkartisan 1.png',
                  width: 200,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24.0)),
                  ),
                  child: SingleChildScrollView(
                    child: BlocProvider(
                      create: (context) => AuthBloc(
                          useApi: false), // Set to true when API is ready
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthSuccess) {
                            CheckartisanNavigator.push(
                                context,
                                OTPVerificationArtisanScreen(
                                    phoneNumber: _phoneController.text));
                          } else if (state is AuthFailure) {
                            AnimatedSnackBar.rectangle(
                                'Error', 'Check Internet Connect',
                                type: AnimatedSnackBarType.error);
                          }
                        },
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Got a Phone Number? Let’s Get Started',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _firstNameController,
                                labelText: 'First Name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _lastNameController,
                                labelText: 'Last Name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                labelText: 'Phone Number',
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                obscureText: _obscurePassword,
                                toggleObscureText: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Confirm Password',
                                obscureText: _obscureConfirmPassword,
                                toggleObscureText: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'CLICK HERE TO READ TERMS AND CONDITIONS',
                                style: TextStyle(
                                  color: Color(0xFF004D40),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Switch(
                                    value: _isSwitched,
                                    onChanged: (bool value) {
                                      setState(() {
                                        _isSwitched = value;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'I agree to the terms and conditions',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (state is AuthLoading)
                                const CircularProgressIndicator()
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final firstName =
                                          _firstNameController.text;
                                      final lastName = _lastNameController.text;
                                      final phoneNumber = _phoneController.text;
                                      final password = _passwordController.text;
                                      final confirmPassword =
                                          _confirmPasswordController.text;

                                      if (password != confirmPassword) {
                                        AnimatedSnackBar.rectangle('Error',
                                                'Password Does Not Match',
                                                type:
                                                    AnimatedSnackBarType.error)
                                            .show(context);
                                      }

                                      context.read<AuthBloc>().add(
                                            RegisterSubmitted(
                                              firstName: firstName,
                                              lastName: lastName,
                                              phoneNumber: phoneNumber,
                                              password: password,
                                            ),
                                          );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF004D40),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shadowColor: Colors.grey.withOpacity(0.5),
                                      elevation: 20,
                                    ),
                                    child: const Text('SIGN UP'),
                                  ),
                                ),
                              const SizedBox(height: 50),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialLoginButton(
                                    onPressed: () {
                                      context
                                          .read<AuthBloc>()
                                          .add(GoogleLogin());
                                    },
                                    label: 'Google account',
                                    assetPath: 'assets/icons/google.png',
                                  ),
                                  const SizedBox(width: 15),
                                  _buildSocialLoginButton(
                                    onPressed: () {
                                      context
                                          .read<AuthBloc>()
                                          .add(FacebookLogin());
                                    },
                                    label: 'Facebook account',
                                    assetPath: 'assets/icons/facebook.png',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () {
                                  CheckartisanNavigator.push(
                                      context, LoginArtisan);
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Already Have an account? ',
                                    style: TextStyle(
                                      color: Colors
                                          .black, // Black color for this part
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'LOGIN',
                                        style: TextStyle(
                                          color: Color(
                                              0xFF004D40), // Green color for this part
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
          labelText: labelText,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback toggleObscureText,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
          labelText: labelText,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: toggleObscureText,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required VoidCallback onPressed,
    required String label,
    required String assetPath,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
            side: BorderSide(color: Colors.grey),
          ),
          textStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          shadowColor: Colors.grey.withOpacity(0.5),
          elevation: 5,
        ),
        icon: Image.asset(
          assetPath,
          height: 30,
          width: 30,
        ),
        label: Text(label),
      ),
    );
  }
}
