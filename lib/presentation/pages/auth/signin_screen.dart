import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/core/theme/text_styleS.dart';
import 'package:rt_app_apk/presentation/components/atoms/logo.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/user_services.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

final ApiServices apiServices = ApiServices();
final UserService userService = UserService(apiServices);

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kkController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obsecureText = true;
  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });
        final success = await userService.signIn(
          _kkController.text,
          _passwordController.text,
        );
        if (success) {
          if (!mounted) return;
          context.go('/dashboard/payment');
        }
      } catch (e) {
        if (!mounted) return;

        String errorMessage = 'Login failed';

        if (e is DioException) {
          // Try to extract error message from response
          final response = e.response;
          if (response != null && response.data != null) {
            if (response.data is Map && response.data['error'] != null) {
              errorMessage = response.data['error'].toString();
            } else {
              errorMessage = response.data.toString();
            }
          } else {
            errorMessage = e.message ?? 'Unknown Dio error';
          }
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _kkController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 83, 127, 231),
      body: SizedBox(
        height: size.height,
        width: double.infinity,
        child: Stack(
          children: [
            ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                height: size.height * 0.38,
                width: double.infinity,
                decoration: BoxDecoration(color: Color(0xFF4A74F0)),
                child: Image.asset(
                  'assets/img/login_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.35,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Mulai Sekarang',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kelola iuran RT Secara Cepat dan Praktis',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 240,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 66, 102, 185),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(70),
                    topRight: Radius.circular(70),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 25,
              right: 25,
              child: Container(
                height: 420,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.only(top: 53, left: 20, right: 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        Text('Nomor Kartu Keluarga'),
                        SizedBox(height: 14),
                        TextFormField(
                          controller: _kkController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color.fromARGB(255, 230, 230, 230),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'KK is required';
                            }
                            if (value.length != 16) {
                              return 'KK must be 16 digits';
                            }
                            if (int.tryParse(value) == null) {
                              return 'KK must be numeric';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text('Password'),
                        SizedBox(height: 14),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obsecureText,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color.fromARGB(255, 230, 230, 230),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obsecureText = !_obsecureText;
                                });
                              },
                              icon: Icon(
                                _obsecureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 46),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorList.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child:
                            _isLoading
                                ? CircularProgressIndicator()
                                : Text(
                              'Login',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 31),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Belum punya akun?'),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => context.go('/sign-up'),
                              child: Text('Sign Up', style: TextStyles.link),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Sign In Button
                      ],
                    ),
                  ),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
