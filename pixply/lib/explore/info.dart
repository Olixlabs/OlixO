import 'package:flutter/material.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pixply/explore/design_game_page.dart';
import 'package:provider/provider.dart';
import 'game_creation_store.dart';
import 'package:flutter/services.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:country_picker/country_picker.dart';

class Info extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const Info({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<Info> createState() => _InfoState();
}
bool _showNameError = false;

class _InfoState extends State<Info> {
  // فعلاً فقط Step 1 داریم
  // int currentStep = 0;

  final nameController = TextEditingController();
  final aboutController = TextEditingController();
  final overviewController = TextEditingController();
  final playerFromController = TextEditingController();
  final playerToController = TextEditingController();
  final ageFromController = TextEditingController();
  final ageToController = TextEditingController();
  

  String selectedCountry = "United Kingdom";

  static const int titleMaxLength = 20;
  static const int overviewMaxLength = 300;

  final Map<String, List<String>> _tips = {
    "What is the name of your game?": [
      "Quick Tip",
      "Enter a short, memorable name for your game. Avoid unnecessary characters."
    ],
    "Game Overview": [
      "Overview",
      "Describe your game briefly: genre, theme, core mechanics, and what makes it unique."
    ],
    "Player Numbers": [
      "Players",
      "Specify the minimum and maximum number of players (e.g., 2–4)."
    ],
    "Age Range": [
      "Age Range",
      "Choose the suitable age group (e.g., 6–9, 10–13)."
    ],
    "Region / Country": [
      "Region / Country",
      "Select the country this game targets; it can affect language and cultural adaptation."
    ],
    "Game Play Description": [
      "Gameplay",
      "Main rules, phases/rounds, and typical time per round—brief and clear."
    ],
    "Instruction Video URL": [
      "Tutorial Video",
      "Paste a valid URL (https://) if you have a how-to video."
    ],
  };

  @override
  void dispose() {
    nameController.dispose();
    aboutController.dispose();
    overviewController.dispose();
    playerFromController.dispose();
    playerToController.dispose();
    ageFromController.dispose();
    ageToController.dispose();
    super.dispose();
  }

 bool _isStep1Valid() => nameController.text.trim().isNotEmpty;

void _goNextIfValidStep1() {
  if (!_isStep1Valid()) {
    setState(() => _showNameError = true);
    return;
  }

  final store = context.read<GameCreationStore>();
  store.setInfo(
    name: nameController.text.trim(),
    about: '',
    overview: '',
    playersFrom: null,
    playersTo: null,
    ageMin: null,
    ageMax: null,
    region: selectedCountry,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DesignGamePage(
        bluetooth: widget.bluetooth,
        isConnected: widget.isConnected,
      ),
    ),
  );
}


  void _closeOrBack() {
    Navigator.pop(context);
  }

  // ----- STEP 1 (Required) -----
  Widget step1() => buildTextStep(
        title: "What is the name of your game?",
        controller: nameController,
        hasInfoIcon: true,
        maxLength: titleMaxLength,
        maxLines: 1,
      );

  // ----- STEP 2/3 فعلاً کامنت -----
  /*
  Widget step2() => buildTextStep(
        title: "Game Overview",
        controller: aboutController,
        hasInfoIcon: true,
        maxLength: overviewMaxLength,
        maxLines: null,
      );

  Widget step3() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildNumberRange(
            title: "Player Numbers",
            fromCtrl: playerFromController,
            toCtrl: playerToController,
          ),
          const SizedBox(height: 40),
          buildNumberRange(
            title: "Age Range",
            fromCtrl: ageFromController,
            toCtrl: ageToController,
          ),
          const SizedBox(height: 40),
          buildDropdown(),
        ],
      );
  */

  Widget buildTextStep({
    required String title,
    required TextEditingController controller,
    bool hasInfoIcon = false,
    int? maxLength,
    int? maxLines,
  }) {
    final isRequired = true; // Step1 اجباری است
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 120,
              ),
              child: Text(
                title + (isRequired ? " *" : ""),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
                softWrap: true,
              ),
            ),
            if (hasInfoIcon) ...[
              const SizedBox(width: 6),
              _infoIcon(title),
            ],
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {
              if (controller == nameController) {
      _showNameError = false;
    }
  }),
          
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins'),
          keyboardType: TextInputType.text,
          minLines: 1,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          maxLengthEnforcement:
              maxLength != null ? MaxLengthEnforcement.enforced : MaxLengthEnforcement.none,
          inputFormatters: maxLength != null
              ? <TextInputFormatter>[LengthLimitingTextInputFormatter(maxLength)]
              : null,
          decoration: InputDecoration(
            hintText: "Required",
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            counterText: '',
             errorText: (controller == nameController &&
            _showNameError &&
            nameController.text.trim().isEmpty)
        ? 'Please enter your game name'
        : null,
    errorStyle: const TextStyle(
      color: Colors.redAccent,
      fontSize: 12,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    ),
  ),
),
        const SizedBox(height: 12),
        Text(
          maxLength != null
              ? "${controller.text.length}/$maxLength ${controller.text.length == 1 ? 'Character' : 'Characters'}"
              : "${controller.text.length} ${controller.text.length == 1 ? 'Character' : 'Characters'}",
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget buildNumberRange({
    required String title,
    required TextEditingController fromCtrl,
    required TextEditingController toCtrl,
    bool hasInfoIcon = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
            if (hasInfoIcon) ...[
              const SizedBox(width: 6),
              _infoIcon(title),
            ],
          ],
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            const Text("From",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 8),
            SizedBox(width: 95, height: 40, child: numberField(fromCtrl)),
            const SizedBox(width: 5),
            const Text("To",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 8),
            SizedBox(width: 95, height: 40, child: numberField(toCtrl)),
          ],
        ),
      ],
    );
  }

  Widget buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Region/Country",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins')),
            const SizedBox(width: 6),
            _infoIcon("Region / Country"),
          ],
        ),
        const SizedBox(height: 40),
        DefaultSelectionStyle(
          cursorColor: Colors.white,
          selectionColor: Colors.white24,
          child: InkWell(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                countryListTheme: CountryListThemeData(
                  backgroundColor: Colors.black,
                  textStyle:
                      const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                  searchTextStyle:
                      const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                  inputDecoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(41),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                onSelect: (Country c) {
                  setState(() => selectedCountry = c.name);
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(52.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCountry,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget numberField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: "",
        filled: true,
        fillColor: const Color(0xFF222222),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(52.5),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _infoIcon(String key, {bool dark = true}) {
    final pair = _tips[key];
    final title = (pair != null && pair.isNotEmpty) ? pair[0] : key;
    final body = (pair != null && pair.length > 1) ? pair[1] : "Info";

    final bg = dark ? const Color(0xFF2A2A2F) : Colors.white;
    final fg = dark ? Colors.white : const Color(0xFF1D1D1F);

    return JustTheTooltip(
      preferredDirection: AxisDirection.up,
      tailLength: 10,
      tailBaseWidth: 18,
      backgroundColor: bg,
      isModal: true,
      margin: const EdgeInsets.all(12),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DefaultTextStyle(
            style: TextStyle(color: fg, height: 1.35, fontFamily: 'Poppins'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: fg.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Semantics(
        label: 'Info: $key',
        button: true,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(Icons.info_outline, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // فقط Step1
    final Widget onlyStep = step1();
    final bool canProceed = _isStep1Valid();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _closeOrBack,
                    child: Container(
                      width: 71,
                      height: 71,
                      decoration: const BoxDecoration(
                        color: Color(0xFF333333),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/close.svg",
                          width: 35,
                          height: 35,
                          colorFilter:
                              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Game Basic Info",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(width: 71),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        child: onlyStep,
                      ),
                    ),

                    // Next (disabled until valid)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: 336,
                        height: 82,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF333333),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(41),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _goNextIfValidStep1,
                          child: const Text(
                            "Next",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
