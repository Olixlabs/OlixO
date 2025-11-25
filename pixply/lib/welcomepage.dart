import 'package:flutter/material.dart';
import 'package:pixply/connected.dart';
import 'package:pixply/UserAccount/signinpage.dart';
import 'package:pixply/UserAccount/signuppage.dart';
import 'package:led_ble_lib/led_ble_lib.dart';


class Welcomepage extends StatelessWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const Welcomepage({super.key, required this.bluetooth, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
      child: Center(
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20 ),
      child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // const SizedBox(height: 20), 
      //  welcome text
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              
        // subtitle text
              Padding(
                padding: const EdgeInsets.only(bottom: 40), 
                child: Column(
                  children: [
                    const Text(
                      'Unroll, Play, Connect',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                    ),
      const SizedBox(height: 40),  

      // create account button       
            SizedBox( width: double.infinity, height: 82, child: ElevatedButton( onPressed: () async {
                final navigator = Navigator.of(context);
  // show a temporary black screen
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SizedBox.expand(child: ColoredBox(color: Colors.black)),
  );

  await Future.delayed(Duration(milliseconds: 500));
  if (!context.mounted) return;
  navigator.pop();
  navigator.push(
    MaterialPageRoute(builder: (_) =>  SignUpPage(bluetooth: bluetooth, isConnected: isConnected,)),
  );
},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF313131),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(41),
                      ),
                      maximumSize: const Size(336, 82), // Set the maximum size
                    ),
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // sign in button
             SizedBox(
                  width: double.infinity,
                  height: 82,
                  child: ElevatedButton(
                   onPressed: () async {
  final navigator = Navigator.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SizedBox.expand(child: ColoredBox(color: Colors.black)),
  );

  await Future.delayed(const Duration(milliseconds: 500));
  if (!context.mounted) return;

  navigator.pop();
  navigator.push(
    MaterialPageRoute(builder: (_) =>  SignInPage( bluetooth: bluetooth, isConnected: isConnected,)),
  );
} ,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF313131),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(41),
                      ),
                      maximumSize: const Size(336, 82),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // continue as guest
                SizedBox(
                  width: double.infinity,
                  height: 82,
                  child: ElevatedButton(
                 onPressed: () async {
  final navigator = Navigator.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SizedBox.expand(child: ColoredBox(color: Colors.black)),
  );

  await Future.delayed(const Duration(milliseconds: 500));
  if (!context.mounted) return;

  navigator.pop();
  navigator.push(
    MaterialPageRoute(builder: (_) => ConnectedPage( bluetooth: bluetooth, isConnected: isConnected,)),
  );
} ,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF313131),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(41),
                      ),
                      maximumSize: const Size(336, 82),
                    ),
                    child: const Text(
                      'Continue as guest',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

  
                const SizedBox(height: 40), 

                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
