import 'package:flutter/material.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pixply/explore/explore.dart';
import 'package:pixply/explore/info.dart';
import 'package:pixply/explore/mycreations.dart';
import 'package:provider/provider.dart';
import 'package:pixply/explore/game_creation_store.dart';
// import 'package:pixply/explore/termsconditionspixstudio.dart';
import 'package:pixply/explore/howtodo.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixply/pixstudio_activation_patch.dart';
// The following imports are used to gather device and network information
// and to send it to an external service (e.g. a make.com webhook). The
// `public_ip_address` package exposes a simple API to obtain the user's
// public IP address, while `device_info_plus` provides details about the
// hardware and operating system. Finally, the `http` package is used
// to make an HTTP POST request to your automation webhook. The `dart:convert`
// library is needed to JSON‑encode the payload before sending it over
// the network. See the package documentation for usage details:
// - public_ip_address: retrieving the public IP address is as simple as
//   calling `IpAddress().getIp()`【618269293193866†L100-L116】.
// - device_info_plus: provides structured device information.
// - http.post: used to send JSON data to a server【504248013398900†L518-L542】.
// import 'dart:convert';
// import 'package:public_ip_address/public_ip_address.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io' show Platform;

class Yourgame extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const Yourgame({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<Yourgame> createState() => _YourgameState();
}

class _YourgameState extends State<Yourgame> {
  // ====== Auth Gate State ======
  static const _kAuthKey = 'pixstudio_v01_authorized';
  // static const _kPasswordHash = 'f2ca1bb6c7e907d06dafe4687e579fce9f0f';  

  final _storage = const FlutterSecureStorage();
  bool _authorized = true; // default unlocked, no activation needed

  @override
  void initState() {
    super.initState();
    // _checkAuth(); // Check if the user is authorized (disabled)
  }

  Future<void> _checkAuth() async {
    // Auth gate disabled: always unlock without asking for activation code.
    setState(() => _authorized = true);

    // Previous implementation kept for reference:
    // final v = await _storage.read(key: _kAuthKey);
    // if (v == 'true') {
    //   setState(() => _authorized = true);
    // } else {
    //   // show popup
    //   await Future<void>.delayed(Duration.zero);
    //   _showPasswordDialog();
    // }
  }

  void _showPasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final textCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false, // can't dismiss by tapping outside
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => true, // disable back button or not 
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                backgroundColor: const Color(0xFF111111),
                title: const Text('Enter Activation Code',
                    style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: textCtrl,
                    obscureText: obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Activation Code',
                      hintStyle: const TextStyle(color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        onPressed: () => setLocal(() => obscure = !obscure),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                    validator: (value) {
                      final input = (value ?? '').trim();
                      // Ensure a code/password is provided; actual validation is performed
                      // against the Make.com webhook in _onSubmit.
                      if (input.isEmpty) return 'Activation code is required';
                      return null;
                    },
                    onFieldSubmitted: (_) => _onSubmit(formKey, textCtrl),
                  ),
                ),
                actions: [
                  TextButton(   // can't dismiss
                      onPressed: () async {
                        
    // close the dialog first
    Navigator.of(context, rootNavigator: true).pop();
    // replace current page with DiscoverPage
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DiscoverPage(
          bluetooth: widget.bluetooth,
          isConnected: widget.isConnected,
        ),
      ),
    );
  },
                    child: const Text('Exit', style: TextStyle(color: Colors.white70)),
                  ),
                  ElevatedButton(
                    onPressed: () => _onSubmit(formKey, textCtrl),
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // String _fakeHash(String s) {
  //   return 'f2ca1bb6c7e907d06dafe4687e579fce9f0f'; 
  // }

  Future<void> _onSubmit(GlobalKey<FormState> key, TextEditingController c) async {
    // Validate form locally (only checks for non-empty input)
    if (!(key.currentState?.validate() ?? false)) return;

    // Normalize the activation code: trim whitespace and convert to uppercase.
    // The automation flow on Make.com expects the code in uppercase form (e.g. "PIX-XXXXXXXX"),
    // so we convert it here before sending. This helps avoid case‑sensitivity issues during
    // activation. Only this line is changed; the rest of the logic remains intact.
    final code = c.text.trim().toUpperCase();
    // Show a simple loading indicator while contacting the Make.com webhook
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final status = await PixStudioActivationPatchWebhook
          .activateViaWebhook(code: code);
      // Close loading overlay
      Navigator.of(context, rootNavigator: true).pop();

      if (status == 'allow') {
        // Mark authorized in local storage (legacy key)
        await _storage.write(key: _kAuthKey, value: 'true');
        if (mounted) {
          setState(() => _authorized = true);
          // Close password dialog
          Navigator.of(context, rootNavigator: true).pop();
        }
        // Notify user of successful unlock
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PixStudio unlocked ✔')),
        );
      } else if (status == 'deny') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This code has already been used on another device.')),
        );
      } else if (status == 'invalid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown response. Please try again.')),
        );
      }
    } catch (e) {
      // Close loading overlay
      Navigator.of(context, rootNavigator: true).pop();
      // Show appropriate error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('no_internet')
                ? 'You must be connected to the internet to activate PixStudio.'
                : 'Network/Server error. Please try again.',
          ),
        ),
      );
    }
  }

  void _exitPageLocked() {
   // if they can't enter the password, just exit
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameCreationStore(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            gradient: null,
          ),
          child: Stack(
            children: [
              // pink
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(247, 188, 52, 1),
                      Colors.transparent
                    ],
                    radius: 1.0,
                    center: Alignment.topLeft,
                  ),
                ),
              ),
              // blue
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(185, 34, 7, 1),
                      Colors.transparent
                    ],
                    radius: 1.0,
                    center: Alignment.centerRight,
                  ),
                ),
              ),
              // green
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(68, 155, 170, 1),
                      Colors.transparent
                    ],
                    radius: 1.0,
                    center: Alignment.bottomLeft,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Header ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () {
                                  Navigator.push( context,
                                  MaterialPageRoute(
                                  builder: (context) => DiscoverPage(
                                  bluetooth: widget.bluetooth,
                                  isConnected: widget.isConnected,
                             ),
                          ),
                       );
                            },
                            child: Container(
                              width: 71,
                              height: 71,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/close.svg',
                                  width: 35,
                                  height: 35,
                                  // ignore: deprecated_member_use
                                  color: Colors.white,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),
                          const Text(
                            'PixStudio V0.1',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 71),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    //buttons
                    buildMenuButton(
                       enabled: _authorized,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      iconPath: 'assets/brush.svg',
                      title: 'Create Your Game',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Info(
                              bluetooth: widget.bluetooth,
                              isConnected: widget.isConnected,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    buildMenuButton(
                       enabled: _authorized,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      iconPath: 'assets/g2088.svg',
                      title: 'My Creation',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyCreationsPage(
                              bluetooth: widget.bluetooth,
                              isConnected: widget.isConnected,
                              gridSize:
                                  8, // Replace 8 with your desired grid size
                              pixelsArgb: const [], // Replace with your actual pixel data if available
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    buildMenuButton(
                       enabled: _authorized,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      iconPath: 'assets/info.svg',
                      title: 'How To Do',
                       onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HowToPage(
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // buildMenuButton(
                    //    enabled: _authorized,
                    //   color: const Color.fromARGB(255, 0, 0, 0),
                    //   iconPath: 'assets/termscondition.svg',
                    //   title: 'Terms & Conditions',
                    //    onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => PixConditionPage(
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuButton({
    Color? color,
    LinearGradient? gradient,
    required String iconPath,
    required String title,
    required VoidCallback onTap,
     required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !enabled,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            borderRadius: BorderRadius.circular(52.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 30),
              SvgPicture.asset(iconPath, width: 36, height: 36),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
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

