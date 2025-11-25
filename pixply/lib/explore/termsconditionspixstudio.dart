// file: brake_condition_page.dart
import 'package:flutter/material.dart';
// If your icons are SVG, keep this import:
import 'package:flutter_svg/flutter_svg.dart';

class PixConditionPage extends StatelessWidget {
  const PixConditionPage({super.key});

  // The exact list content provided by the user (11 sections).
  final List<Map<String, String>> _items = const [
  {
    "title": "1. Eligibility",
    "subtitle":
        "• You must be at least 13 years old to use the app.\n• If the laws of your country require a higher minimum age (e.g., 14 or 16), you must comply with that requirement.\n• Children under 13 are not permitted to use Pixply."
  },
  {
    "title": "2. Account Information",
    "subtitle":
        "• You must provide accurate and up-to-date information when creating an account.\n• You are responsible for keeping your password and login details secure.\n• Any activity under your account is your responsibility."
  },
  {
    "title": "3. Acceptable Use",
    "subtitle":
        "You agree not to:\n• Use the app for illegal or harmful purposes (spam, fraud, hacking, malware).\n• Upload offensive, hateful, pornographic, or infringing content.\n• Copy, reverse-engineer, or attempt to interfere with the app.\n• Use the app for unauthorized commercial purposes.\n\nViolation may result in suspension or termination of your account."
  },
  {
    "title": "4. Intellectual Property",
    "subtitle":
        "• All content, software, and designs in Pixply are the property of Pixply Ltd.\n• You are granted a personal, non-transferable license to use the app.\n• You may not copy, modify, or redistribute Pixply software or content without permission."
  },
  {
    "title": "5. Purchases and Payments",
    "subtitle":
        "• Purchases are processed through Pixply’s official website (Shopify).\n• Payments are handled securely by Shopify.\n• Refunds and returns follow Pixply’s website policy:\n  • Hardware can be returned within 14 days if unused and in original packaging.\n  • Refund requests must follow the Refund & Cancellation Policy.\n• Depending on your country, you may also have additional consumer rights (e.g., EU, UK, or Australian law)."
  },
  {
    "title": "6. Privacy and Data Protection",
    "subtitle":
        "• Your data is collected and processed in accordance with the Pixply Privacy Policy.\n• We comply with international data protection laws including GDPR, CCPA, and COPPA.\n• For questions or data requests, contact: support@pixply.io"
  },
  {
    "title": "7. PixStudio / User-Generated Content",
    "subtitle":
        "• You retain all rights to any content (drawings, designs, data) you create or upload via PixStudio, provided it doesn’t infringe third-party rights.\n• You grant Pixply a limited, non-exclusive, non-transferable license to use your content only locally on your device / board, for your own private use.\n• PixStudio is designed for local/private use only. Your content will not be published, shared with others, or used commercially by Pixply without your explicit consent.\n• You are responsible for ensuring your content is lawful, does not violate copyright, trademark, privacy or other legal rights of any third party.\n• Pixply is not liable for any claims arising from your User Content. You agree to indemnify Pixply if your content causes legal issues.\n• If we become aware of content that violates these terms or applicable law, we may remove or block it, even if stored locally."
  },
  {
    "title": "8. Termination of Accounts",
    "subtitle":
        "• You may delete your account at any time.\n• Pixply Ltd may suspend or terminate your account if you break these Terms or use the app unlawfully."
  },
  {
    "title": "9. Limitation of Liability",
    "subtitle":
        "• The app is provided \"as is\" and \"as available.\" \n• Pixply Ltd is not liable for indirect or consequential damages (e.g., data loss, lost profits).\n• Our maximum liability is limited to the amount you paid to Pixply in the last 12 months."
  },
  {
    "title": "10. Changes to Terms",
    "subtitle":
        "• Pixply Ltd may update these Terms from time to time.\n• Significant changes will be notified within the app or on our website.\n• Continued use of the app after changes means you accept the updated Terms."
  },
  {
    "title": "11. Governing Law",
    "subtitle":
        "• These Terms are governed by the laws of England and Wales.\n• Disputes shall be resolved in the courts of England, unless local consumer law requires otherwise."
  },
  {
    "title": "12. Contact Us",
    "subtitle":
        "If you have any questions about these Terms, please contact us:\nsupport@pixply.io\nwww.pixply.io"
  },
];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // No AppBar as requested
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // 20 padding on all sides
          child: Stack(
            children: [
              // Main scrollable content
              ListView(
                // Page is scrollable
                physics: const AlwaysScrollableScrollPhysics(),
                // ensure list content is not hidden behind the fixed button:
                padding: const EdgeInsets.only(bottom: 140),
                children: [
                  // Header: back icon (inside 71x71 circle) + long title + subtitle
                  Directionality(
                    // Ensure left-to-right layout for title and subtitle
                    textDirection: TextDirection.ltr,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button inside a 71x71 circle
// جای Container قبلی:
Material(
  color: const Color(0xFF333333),
  shape: const CircleBorder(),
  child: InkWell(
    customBorder: const CircleBorder(),
    onTap: () async {
      await Navigator.maybePop(context); // ایمن‌تر از pop
    },
    child: SizedBox(
      width: 71,
      height: 71,
      child: Center(
        child: SvgPicture.asset(
          "assets/back.svg",
          width: 35,
          height: 35,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    ),
  ),
),


                        const SizedBox(width: 20), // 20 spacing between icon and title

                        // Title (long) and subtitle below. Expanded prevents overflow.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                // Replace this with your actual long title
                                'Terms & Conditions',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                                softWrap: true,
                                maxLines: null,
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Last Update: 9/19/2025',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // The rest of the page: a list of items (title + description)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _ListItem(
                        title: item['title'] ?? '',
                        subtitle: item['subtitle'] ?? '',
                      );
                    },
                  ),

                  // Keep consistent bottom spacing (extra safe)
                  const SizedBox(height: 20),
                ],
              ),

              // Fixed bottom button (positioned 20 from bottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(49, 49, 49, 1),
                    borderRadius: BorderRadius.circular(41),
                  ),
                  child: TextButton(
  onPressed: () async {
    Navigator.of(context).pop(true);
    // If you want to ensure the page is popped only if possible:
    // await Navigator.maybePop(context);
  },

                    child: const Center(
                      child: Text(
                        'I agree to the Pixstudio Terms & Conditions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ListItem({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
