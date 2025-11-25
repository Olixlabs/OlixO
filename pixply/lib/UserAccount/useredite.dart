// user_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:pixply/UserAccount/user_service.dart';

class UserPageEdite extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const UserPageEdite({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<UserPageEdite> createState() => _UserPageEditeState();
}

class _UserPageEditeState extends State<UserPageEdite> with SingleTickerProviderStateMixin {
  // data
  String userName = "Daniel Moradi";
  String userEmail = "danielmoradiprogrammer@gmail.com";
  String userPassword = "";

  // layout constants
  final double _tileHeight = 82;
  final double _tileBorderRadius = 41;

  // expansion state 
  final Map<String, bool> expandedSections = {
    'username': false,
    'email address': false,
    'password': false,
  };
  
  final Map<String, GlobalKey> _expKeys = {
    'username': GlobalKey(),
    'email address': GlobalKey(),
    'password': GlobalKey(),
  };
  final Map<String, double> _expHeights = {};

  // form & controllers
  final _formKey = GlobalKey<FormState>();
  // final _usernameCtrl = TextEditingController();
  // final _emailCtrl = TextEditingController();
  // final _passCtrl = TextEditingController();
  // bool _saving = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // image picker (kept import but not used as requested)
  // final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController.text = userName;
    _emailController.text = userEmail;
    _prefill();
  }
Future<void> _prefill() async {
  final p = await UserService.fetchProfile();
  if (!mounted) return;  
  _usernameController.text = p.username;
  _emailController.text = p.email;
  setState((){}); // refresh UI if needed
}
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  //    _usernameCtrl.dispose();
  // _emailCtrl.dispose();
  // _passCtrl.dispose();
    super.dispose();
  }

  void toggleSection(String key) {
    setState(() {
      final wasOpen = expandedSections[key] ?? false;
      // close all
      expandedSections.updateAll((k, v) => false);
      // toggle this one
      expandedSections[key] = !wasOpen;
    });
  }

  // ========== SAVE (UPDATE) ==========
  Future<void> _saveProfile() async {
    // validate
    if (!_formKey.currentState!.validate()) return;

    // show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // simulate network / processing delay
    await Future.delayed(const Duration(seconds: 1));

     if (!mounted) {                                    // ADD
    return;
  }

    // update local data
    setState(() {
      userName = _usernameController.text.trim();
      userEmail = _emailController.text.trim();
      userPassword = _passwordController.text;
      // close expanded sections after save
      expandedSections.updateAll((key, value) => false);
    });

    // remove loader
    if (!mounted) return;  
    Navigator.pop(context);

    // feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  // ========== UI helpers ==========
  Widget _buildTile(
    String label, {
    VoidCallback? onTap,
    String? rightText,
    String? iconPath,
    bool useGreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _tileHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: useGreen ? const Color(0xFF8BFF84) : const Color(0xFF9E9E9E),
          borderRadius: BorderRadius.circular(_tileBorderRadius),
        ),
        child: Row(
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(Color(0xFF000000), BlendMode.srcIn),
              ),
            Text(
              label,
              style: TextStyle(
                color: useGreen ? Colors.black : Colors.black87,
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
                color: Colors.black87,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
      ),
      child: SizedBox(width: double.infinity, child: child),
    );
  }

  void _captureExpandedHeight(String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _expKeys[key]?.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final h = box.size.height;
      if ((_expHeights[key] ?? -1) != h) {
        setState(() => _expHeights[key] = h);
      }
    });
  }

  Widget _buildExpandableItem({
    required String label,
    required Widget tile,
    required Widget expandedChild,
    required bool expanded,
    double overlap = 16, // همان 16px زیر تایتل
  }) {
    final keyId = label.toLowerCase();

    // اگر باز است، قد محتوا را اندازه بگیر
    if (expanded) _captureExpandedHeight(keyId);

    final measured = _expHeights[keyId] ?? 0.0;

    // ارتفاع واقعی گروه: قد تایتل + (قد محتوا - اورلپ)
    final double targetHeight = _tileHeight +
        (expanded ? (measured - overlap).clamp(0, double.infinity) : 0.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: targetHeight, // اینجا فضا واقعاً به لایوت اضافه می‌شود
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (expanded)
                Positioned(
                  top: _tileHeight - overlap,
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _expKeys[keyId],
                    child: _buildExpandedBox(
                      expandedChild,
                      bottomRadius: _tileBorderRadius,
                    ),
                  ),
                ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _tileHeight,
                child: tile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const double logoutHeight = 82;
    const double logoutGap = 20;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MediaQuery.removeViewInsets(
          removeBottom: true, 
          context: context,
          child: Container(
            margin: const EdgeInsets.fromLTRB(80, 0, 80, 20),
            height: 82, // = logoutHeight
            decoration: BoxDecoration(
              color: const Color.fromRGBO(147, 255, 131, 1),
              borderRadius: BorderRadius.circular(41),
            ),
            child: TextButton(
            onPressed: () => _saveProfile(),   
              child: const Center(
                child: Text(
                  'Update',
                  style: TextStyle(
                    color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Scrollable content — padding bottom prevents content being hidden under logout
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: logoutHeight + logoutGap + bottomSafe + 36),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                        const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  // ** بخش پروفایل حذف شد (avatar + display) **

                  const SizedBox(height: 28),

                  // --- editable sections ---
                  // Username
                  _buildExpandableItem(
                    label: 'Username',
                    tile: _buildTile(
                      'Username',
                      onTap: () => toggleSection('username'),
                      useGreen: false,
                    ),
                    expanded: expandedSections['username'] == true,
                    overlap: 30,
                    expandedChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter username',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter username' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Email address
                  _buildExpandableItem(
                    label: 'Email address',
                    tile: _buildTile(
                      'Email address',
                      onTap: () => toggleSection('email address'),
                      useGreen: false,
                    ),
                    expanded: expandedSections['email address'] == true,
                    overlap: 30,
                    expandedChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter email',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password
                  _buildExpandableItem(
                    label: 'Password',
                    tile: _buildTile(
                      'Password',
                      onTap: () => toggleSection('password'),
                      useGreen: false,
                    ),
                    expanded: expandedSections['password'] == true,
                    overlap: 30,
                    expandedChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter new password',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          validator: (v) {
                            if (expandedSections['password'] == true) {
                              if (v == null || v.trim().length < 6) return 'Password must be 6+ chars';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
