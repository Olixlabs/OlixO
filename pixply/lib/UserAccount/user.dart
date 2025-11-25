import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/UserAccount/useredite.dart';
import 'package:pixply/UserAccount/user_service.dart';
import 'package:pixply/welcomepage.dart';
class UserPage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const UserPage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String userName = "Daniel Moradi";
  String userEmail = "danielmoradiprogrammer@gmail.com";
  final double _tileHeight = 82;
  final double _tileBorderRadius = 41;
  
   final Map<String, bool> expandedSections = {
    'tools available': false,
    'payment method': false,
    'billing address': false,
  };

   double brightness = 0.5;
   bool _loading = true;

@override
void initState() {
  super.initState();
  _load();
}
Future<void> _load() async {
  try {
    final p = await UserService.fetchProfile();
    if (!mounted) return;
    setState(() { _loading = false;  userName = p.username;
      userEmail = p.email;});
  } catch (_) {
    if (!mounted) return;
    setState(() { _loading = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load profile')),
    );
  }
}
   void toggleSection(String key) {
    setState(() {
      expandedSections[key] = !(expandedSections[key] ?? false);
    });
  }
Future<void> _logout() async {
  await UserService.logout(); // clear token and profile
  if (!mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => Welcomepage(bluetooth: widget.bluetooth, isConnected: widget.isConnected)),
    (route) => false,
  );
}

    Widget _buildTile(
    String label, {
    VoidCallback? onTap,
    String? rightText,
    String? iconPath,
    bool useGreen = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _tileHeight,
      //  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: useGreen ? const Color(0xFF8BFF84) : const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(_tileBorderRadius),
        ),
        child: Row(
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 36,
                height: 36,
                  colorFilter: ColorFilter.mode(
                          Colors.black,
                        BlendMode.srcIn)
                    ,
              ),
         
            Text(
              label,
              style: TextStyle(
                color: useGreen ? Colors.black : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
               ),
            const Spacer(),
            if (rightText != null)
              Text(
                rightText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
              if (expandedSections.containsKey(label.toLowerCase()))
              Icon(
                expandedSections[label.toLowerCase()] == true
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: useGreen ? Colors.black : Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  } 
    Widget _buildExpandedBox(Widget child, {double bottomRadius = 41}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // margin: const EdgeInsets.only(top: 0, bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // height: 90,
      // width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
         borderRadius: BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
        bottomLeft: Radius.circular(bottomRadius),
        bottomRight: Radius.circular(bottomRadius),
      ),
      ),
      child: SizedBox(
        width: double.infinity,
      child: child,
      ),
    );
  }


  Widget _buildExpandableItem({
  required String label,
  required Widget tile,
  required Widget expandedChild,
  required bool expanded,
  double overlap = 16,
  }) {
  final double safeOverlap = overlap.clamp(0, _tileHeight - 8);
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
   child: Stack(
      clipBehavior: Clip.none,
       children: [
       if (expanded)
          Positioned(
            top: _tileHeight - safeOverlap,
            left: 0,
            right: 0,
            child: _buildExpandedBox(
              expandedChild,
              bottomRadius: _tileBorderRadius,
            ),
          ), 
          SizedBox(
          height: _tileHeight,
          child: tile,
        ),
      ],
    ),
  );
}   
@override
Widget build(BuildContext context) {
  final bottomSafe = MediaQuery.of(context).padding.bottom;
  const double logoutGap = 20;
  return Scaffold(
    backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
    body: Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // --- Header ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 71,
                      height: 71,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      child: IconButton(
                        icon: SvgPicture.asset('assets/arrow.svg',
                            width: 36, height: 36),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Text(
                      'Profile',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Container(
                      width: 71,
                      height: 71,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      child:IconButton(
                      onPressed: _loading ? null : () async {
                      final updated = await Navigator.push(
                       context,
                            MaterialPageRoute(
                              builder: (context) => UserPageEdite(
                                bluetooth: widget.bluetooth,
                                isConnected: widget.isConnected,
                              ),
                            ),
                          );
                          if (!mounted) return;
                         if (updated == true) { _load(); } 
                        },
                        icon: SvgPicture.asset(
                          'assets/edit.svg',
                          width: 33,
                          height: 33,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
                   Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // avatar circle
                // Container(
                //   width: 120,
                //   height: 120,
                //   decoration: const BoxDecoration(
                //     shape: BoxShape.circle,
                //     color: Colors.transparent,
                //   ),
                //   child: CircleAvatar(
                //     radius: 60,
                //     backgroundColor: Colors.white12,
                //     backgroundImage: avatarUrl != null
                //         ? NetworkImage(avatarUrl!)
                //         : null,
                //    child: avatarUrl == null
                //         ? const Icon(
                //             Icons.person,
                //             size: 48,
                //             color: Colors.white70,
                //           )
                //         : null,
                //   ),
                // ),
                const SizedBox(height: 12),   
                    Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --- tiles ---
            // Device name (example with small right text)
           Container(
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: _buildTile(
    'Device name',
    onTap: () { /* ... */ },
    rightText: 'Pixply 52358',
    useGreen: true,
  ),
),

            // Tools available (expandable)
_buildExpandableItem(
  label: 'Tools available',
  tile: _buildTile(
    'Tools available',
    onTap: () => toggleSection('tools available'),
    useGreen: true,
  ),
  expanded: expandedSections['tools available'] == true,
  overlap: 30, 
  expandedChild: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      SizedBox(height: 20),
      Text('Tool A', style: TextStyle(color: Colors.white)),
      SizedBox(height: 8),
      Text('Tool B', style: TextStyle(color: Colors.white)),
    ],
  ),
),
// _buildExpandableItem(
//   label: 'Payment method',
//   tile: _buildTile(
//     'Payment method',
//     onTap: () => toggleSection('Payment method'),
//     useGreen: true,
//   ),
//   expanded: expandedSections['Payment method'] == true,
//   overlap: 30, 
//   expandedChild: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: const [
//       SizedBox(height: 20),
//       Text('Tool A', style: TextStyle(color: Colors.white)),
//       SizedBox(height: 8),
//       Text('Tool B', style: TextStyle(color: Colors.white)),
//     ],
//   ),
// ),
// _buildExpandableItem(
//   label: 'Billing address',
//   tile: _buildTile(
//     'Billing address',
//     onTap: () => toggleSection('Billing address'),
//     useGreen: true,
//   ),
//   expanded: expandedSections['Billing address'] == true,
//   overlap: 30, 
//   expandedChild: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: const [
//       SizedBox(height: 20),
//       Text('Tool A', style: TextStyle(color: Colors.white)),
//       SizedBox(height: 8),
//       Text('Tool B', style: TextStyle(color: Colors.white)),
//     ],
//   ),
// ),




            // Billing address

            const SizedBox(height: 20,)
            ],
          ),
        ),


Positioned(
  left: 0,
  right: 0,
   bottom: logoutGap + bottomSafe,
  child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 80),
    height: 82,
    decoration: BoxDecoration(
      color: const Color(0xFF9E9E9E),
      borderRadius: BorderRadius.circular(41),
    ),
    child: TextButton(
    onPressed: () async => _logout(),
      child: const Center(
        child: Text(
          'Logout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    ),
  ),
),

      ],
    ),
  );
}
}
