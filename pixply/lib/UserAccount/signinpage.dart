import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pixply/UserAccount/signuppage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pixply/connected.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:led_ble_lib/led_ble_lib.dart';


class SignInPage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const SignInPage({super.key, required this.bluetooth, required this.isConnected});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
   final _formKey = GlobalKey<FormState>();
   final _storage = const FlutterSecureStorage();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _remember = false;
  bool _obscure = true;
  bool _loading = false;



// note : replace this method with your API call
    Future<String?> _signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) return null;
    // Simulate sign-in process
    return "Bearer your.jwt.token";
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

 Future<void> _handleSignIn({
   required String email,
  required String password,
}) async {
    // validate
   if (_formKey.currentState != null) {
    final ok = _formKey.currentState!.validate(); 
    if (!ok) return;
  }

  setState(() => _loading = true);
  final token = await _signIn(email.trim(), password);
  if (mounted) setState(() => _loading = false);

  if (token == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in failed. Check your credentials.')),
    );
    return;
  }

    // save token
    await _storage.write(key: 'auth_token', value: token);

    if (!context.mounted) return;

    // navigate to home
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ConnectedPage( bluetooth: widget.bluetooth, isConnected: widget.isConnected,)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 520;
    const double fixedButtonWidth = 336.0;
    const double fixedButtonHeight = 82.0;
    final double availableButtonWidth = math.max(0, width - 40);
    final double buttonWidth = math.min(fixedButtonWidth, availableButtonWidth);

    final double horizontalPadding = 20.0;
    final double topOffset = MediaQuery.of(context).padding.top + 20.0;
    final double bottomOffset = MediaQuery.of(context).padding.bottom + 20.0;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: topOffset,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          "Sign In",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.0,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Container(
                        width: 71,
                        height: 71,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 35,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                      padding: EdgeInsets.only(bottom: keyboardHeight + bottomOffset + 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            "Email",
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: 20),
                          ),
                          TextField(
                            controller: _email,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color.fromRGBO(147, 255, 131, 1),
                            decoration: const InputDecoration(
                              hintText: "Enter Email",
                              hintStyle: TextStyle(color: Color.fromRGBO(49, 49, 49, 1)),
                              contentPadding: EdgeInsets.only(top: 20),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color.fromRGBO(255, 255, 255, 1)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color.fromRGBO(147, 255, 131, 1)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            "Password",
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: 20),
                          ),
                          TextField(
                            controller: _pass,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color.fromRGBO(147, 255, 131, 1),
                            decoration: InputDecoration(
                              hintText: "Enter Password",
                              hintStyle: const TextStyle(color: Color.fromRGBO(49, 49, 49, 1)),
                              contentPadding: const EdgeInsets.only(top: 20),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color.fromRGBO(147, 255, 131, 1)),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _remember = !_remember),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 21,
                                      height: 21,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _remember ? const Color.fromRGBO(147, 255, 131, 1) : Colors.grey,
                                          width: 2.6,
                                        ),
                                        color: Colors.black,
                                      ),
                                      child: _remember
                                          ? const Center(
                                              child: SizedBox(
                                                width: 11,
                                                height: 11,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Remember me",
                                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Forget Password",
                                  style: TextStyle(color: Color.fromRGBO(147, 255, 131, 1), fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: fixedButtonHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(41),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(0, 6), blurRadius: 10)],
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading   ? null
                                  : () => _handleSignIn( 
                                    email: _email.text,
                                    password: _pass.text,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Center(
                            child: Text(
                              "Or Sign In With",
                              style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset('assets/google.svg', width: 50, height: 50, fit: BoxFit.contain),
                                ),
                              ),
                              SizedBox(width: isWide ? 40 : 28),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset('assets/apple.svg', width: 50, height: 50, fit: BoxFit.contain, colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: bottomOffset,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) =>  SignUpPage( bluetooth: widget.bluetooth, isConnected: widget.isConnected,)));
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don’t have an account? ",
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      children: [
                        TextSpan(
                          text: " Sign Up",
                          style: TextStyle(color: Color.fromRGBO(147, 255, 131, 1), fontWeight: FontWeight.w400, fontFamily: 'Poppins', fontSize: 14),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
