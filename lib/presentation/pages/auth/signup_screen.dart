import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/core/theme/text_styleS.dart';
import 'package:rt_app_apk/presentation/components/atoms/logo.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/user_services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

final ApiServices apiServices = ApiServices();
final UserService userService = UserService(apiServices);

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
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
        final data = await userService.signUp(
          _kkController.text,
          _passwordController.text,
          _nameController.text,
          _addressController.text,
        );
        if (data) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Register success')));
            context.go('/sign-in');
          }
        }
      } catch (e) {
        if (!mounted) return;

        String errorMessage = 'Register failed';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Selamat Datang di SIMPRUG!',
                            style: TextStyle(
                              fontSize: 20,
                              color: ColorList.primary900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            textAlign: TextAlign.justify,
                            'Daftar untuk menggunakan layanan iuran RT digital',
                            style: TextStyle(color: ColorList.primary900),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: -10,
                    right: -50,
                    child: Container(
                      height: 240,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 66, 102, 185),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(200),
                          topRight: Radius.circular(150),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 25,
                    right: 25,
                    child: Container(
                      height: 620,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: EdgeInsets.only(top: 53, left: 20, right: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //name
                            Text('Nama Lengkap'),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _nameController,
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
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Alamat'),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _addressController,
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
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14),
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
                            const SizedBox(height: 14),

                            // Password
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
                            const SizedBox(height: 24),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submit,
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
                                          'Sign Up',
                                          style: TextStyle(color: Colors.white),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sudah punya akun?'),
                                SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => context.go('/sign-in'),
                                  child: Text('Log In', style: TextStyles.link),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
