import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pixply/explore/game_preview.dart';

class MyCreationsPage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;
  
  
  const MyCreationsPage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
    required int gridSize,
    required List<int> pixelsArgb,
  });

  @override
  State<MyCreationsPage> createState() => _MyCreationsPageState();
}

class _MyCreationsPageState extends State<MyCreationsPage> {

  // popup delete
Future<bool?> _showDeleteConfirm(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320), // جلوگیری از پهن شدن بیش از حد
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF5A5A5A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'You are removing your creation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Yes Remove
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(255, 141, 131, 1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(41),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Yes Remove',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cancel
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



static const double leftPadding = 16.0;

@override
  Widget build(BuildContext context) {
    final box = Hive.box<Map>('my_creations');
    return Scaffold(
      backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
      // SafeArea + custom header so we can put the circular back icon 71x71
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: 92, // enough to fit the 71 circle and vertical spacing
              child: Stack(
                children: [
                  // Centered title "Apps"
                  Center(
                    child: Text(
                      'My Creations',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),

                  // Left circular back button positioned with left padding
                  Positioned(
                    left: leftPadding,
                    top: 10, // so the 71 circle is vertically centered within the 92 height
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 71,
                        height: 71,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 0, 0, 0), // similar style as discover header
                        ),
                        child: IconButton(
                          icon: SvgPicture.asset('assets/arrow.svg',
                              width: 36, height: 36),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Container(
              height: 1, 
              color: Colors.white.withValues(alpha: 0.20),
                ),
          ),
            // Spacer to separate header from body
            const SizedBox(height: 20),

            // Body: show the same app shortcuts (you can expand this to more items)
            // I'll show them in a vertical list with same style cards as in DiscoverPage.
             Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ValueListenableBuilder<Box<Map>>(
                  valueListenable: box.listenable(),
                  builder: (context, b, _) {
                    final keys = b.keys.cast<String>().toList()
                      ..sort((a, c) => c.compareTo(a)); // first the most recent

                    if (keys.isEmpty) {
                      return const Center(
                        child: Text(
                          'No creations yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: keys.length,
                      itemBuilder: (_, i) {
                        final id = keys[i];
                        final m = b.get(id)!;
                        final name = (m['name'] ?? '') as String;
                        // final region = (m['region'] ?? '') as String?;
                        final createdAt =
                            DateTime.tryParse(m['createdAt'] ?? '');

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  // if (region != null && region.isNotEmpty)
                                  //   region,
                                  if (createdAt != null)
                                    createdAt
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                                ].join(' • '),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>  GamePreviewPage(bluetooth: widget.bluetooth, isConnected: widget.isConnected,),
                                    settings: RouteSettings(arguments: id),
                                  ),
                                );
                              },
                              trailing: IconButton(
                               icon: SvgPicture.asset('assets/garbag.svg', width: 35, height: 35),
                                 onPressed: () async {
                                final confirmed = await _showDeleteConfirm(context);
                                if (confirmed == true) {
                                  // Also clear the board if something is currently displayed
                                  try {
                                    await widget.bluetooth.deleteAllPrograms();
                                  } catch (_) {}

                                  await b.delete(id);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Removed')),
                                  );
                                }
                              },

                              ),
                            ),
                          
                            // Divider(
                            //   height: 1,
                            //   thickness: 1,
                            //   color: Colors.white.withValues(alpha: 0.08),
                            // ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
