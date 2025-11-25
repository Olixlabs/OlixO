import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixply/connected.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:flutter/gestures.dart';


class SignUpPage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const SignUpPage({super.key , required this.bluetooth, required this.isConnected});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  bool _loading = false;

  bool _agree = false;
  bool _obscure = true;

  Future<String?> _signUp(String username, String email, String password) async {
  // note : replace this method with your API call
  await Future.delayed(const Duration(milliseconds: 700));
  if (username.isEmpty || email.isEmpty || password.isEmpty) return null;
  return "Bearer your.jwt.token";
}

// personal data 
void _showPersonalDataPopup() {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Privacy Policy – Personal Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. What We Collect\n'
                '- Name, email, password\n'
                '- Device and usage data (games, designs, preferences)\n'
                '- Payment info (only if you make purchases)\n\n'
                '2. How We Use It\n'
                '- Create and manage your account\n'
                '- Sync with your Pixply board\n'
                '- Save designs and game progress\n'
                '- Improve features and provide support\n\n'
                '3. Sharing\n'
                '- We do not sell your data.\n'
                '- Shared only with service providers (hosting, payments, analytics).\n\n'
                '4. Your Rights\n'
                '- Access or delete your data anytime\n'
                '- Withdraw consent (may limit features)\n\n'
                '5. Security\n'
                'We use encryption and secure storage to protect your data.\n\n'
                '6. Contact\n'
                'For questions, email: privacy@pixply.com',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(147, 255, 131, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
// end
  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

Future<void> _handleSignUp({
  required String username,
  required String email,
  required String password,
  bool agreedToTerms = true, // اگر چک‌باکس داری، مقدار واقعی‌اش را پاس بده
}) async {
  if (_formKey.currentState != null) {
    final ok = _formKey.currentState!.validate(); // الگوی رسمی ولیدیشن فرم :contentReference[oaicite:7]{index=7}
    if (!ok) return;
  }
  if (!agreedToTerms) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please accept the Terms to continue.')),
    );
    return;
  }

  setState(() => _loading = true);
  final token = await _signUp(username.trim(), email.trim(), password);
  if (mounted) setState(() => _loading = false);

  if (token == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign up failed. Try different credentials.')),
    );
    return;
  }

  await _storage.write(key: 'auth_token', value: token); // save token :contentReference[oaicite:8]{index=8}
 
await const FlutterSecureStorage().write(key: 'profile_username', value: _username.text.trim());
await const FlutterSecureStorage().write(key: 'profile_email', value: _email.text.trim());

  if (!mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) =>  ConnectedPage( bluetooth: widget.bluetooth, isConnected: widget.isConnected,)),
    (route) => false,
  ); // پاک‌کردن استک و رفتن به ConnectedPage :contentReference[oaicite:9]{index=9}
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
                  padding: EdgeInsets.only(top: topOffset, left: horizontalPadding, right: horizontalPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          "Sign Up",
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
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 35, color: Colors.white),
                          onPressed: () => Navigator.maybePop(context),
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
                            "Username",
                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _username,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color.fromRGBO(147, 255, 131, 1),
                            decoration: const InputDecoration(
                              hintText: "Enter Full Name",
                              hintStyle: TextStyle(color: Color.fromRGBO(49, 49, 49, 1)),
                              contentPadding: EdgeInsets.only(top: 12),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255))),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(147, 255, 131, 1))),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            "Email",
                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color.fromRGBO(147, 255, 131, 1),
                            decoration: const InputDecoration(
                              hintText: "Enter Email",
                              hintStyle: TextStyle(color: Color.fromRGBO(49, 49, 49, 1)),
                              contentPadding: EdgeInsets.only(top: 12),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255))),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(147, 255, 131, 1))),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            "Password",
                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _pass,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color.fromRGBO(147, 255, 131, 1),
                            decoration: InputDecoration(
                              hintText: "Enter Password",
                              hintStyle: const TextStyle(color: Color.fromRGBO(49, 49, 49, 1)),
                              contentPadding: const EdgeInsets.only(top: 12),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(147, 255, 131, 1))),
                              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]), onPressed: () => setState(() => _obscure = !_obscure)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () => setState(() => _agree = !_agree),
                            child: Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // Custom round checkbox
    GestureDetector(
      onTap: () => setState(() => _agree = !_agree),
      child: Container(
        width: 21,
        height: 21,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _agree ? const Color.fromRGBO(147, 255, 131, 1) : Colors.grey,
            width: 2.6,
          ),
          color: Colors.black,
        ),
        child: _agree
            ? const Center(
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              )
            : null,
      ),
    ),
    const SizedBox(width: 10),

    // Text with clickable "Personal Data"
    Flexible(
      child: Text.rich(
        TextSpan(
          text: "I agree to the processing of ",
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: "Personal Data",
              style: const TextStyle(
                color: Color.fromRGBO(147, 255, 131, 1),
                fontFamily: 'Poppins',
                fontSize: 14,
                decoration: TextDecoration.underline, // subtle visual cue
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = _showPersonalDataPopup, // <-- open popup here
            ),
          ],
        ),
      ),
    ),
  ],
),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: fixedButtonHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(0, 6), blurRadius: 10)],
                                ),
                                child: ElevatedButton(
                                  onPressed:_loading
                                  ? null
                                  : () => _handleSignUp( username: _username.text, email: _email.text, password: _pass.text, agreedToTerms: _agree, ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text("Sign Up", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          const Center(child: Text("Or Sign Up With", style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14))),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Container(width: 50, height: 50, alignment: Alignment.center, child: SvgPicture.asset('assets/google.svg', width: 50, height: 50, fit: BoxFit.contain)),
                              ),
                              SizedBox(width: isWide ? 40 : 28),
                              GestureDetector(
                                onTap: () {},
                                child: Container(width: 50, height: 50, alignment: Alignment.center, child: SvgPicture.asset('assets/apple.svg', width: 50, height: 50, fit: BoxFit.contain, colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn)))),
                            ],
                          ),
                          const SizedBox(height: 100),
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
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14),
                      children: [
                        TextSpan(text: " Sign In", style: TextStyle(color: Color.fromRGBO(147, 255, 131, 1), fontWeight: FontWeight.w400, fontFamily: 'Poppins', fontSize: 14))
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
