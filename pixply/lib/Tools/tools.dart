// import 'package:flutter/material.dart';
// // import 'digitaldice.dart';
// class ToolsSection extends StatelessWidget {
//   const ToolsSection({super.key});
//    void _showComingSoon(BuildContext context) {
//    ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Coming soon'),
//         behavior: SnackBarBehavior.floating,
//         duration: Duration(seconds: 2),
//       ),
//     );
//   } 
//  Widget _toolsItem( BuildContext context, IconData icon, String title, {
//     VoidCallback? onTap,
//   }) {
//   return Container(
//         width: double.infinity,
//         height: 82,
//         margin: const EdgeInsets.symmetric(vertical: 10),
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Material(
//         color: const Color(0xFF2F2F2F),
//         borderRadius: BorderRadius.circular(41),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(41),
//            onTap: onTap ?? () => _showComingSoon(context),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 Container(
//                   width: 43,
//                   height: 43,
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(icon, color: Colors.black87, size: 22),
//                 ),
//                 const SizedBox(width: 18),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w400,
//                     fontFamily: 'Poppins',
//                     letterSpacing: 0.2,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//      return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
//         decoration: BoxDecoration(
//           color: const Color(0xFF8A8A8A),
//           borderRadius: BorderRadius.circular(37),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 43,
//                   height: 43,
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(Icons.build, color: Colors.black87),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Tools',
//                   style: TextStyle(
//                     color: Color.fromRGBO(147, 255, 131, 1),
//                     fontSize: 24,
//                     fontWeight: FontWeight.w600,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Items 
//             _toolsItem(context, Icons.palette, 'Themes'),
//             _toolsItem(context, Icons.casino, 'Digital Dice'),
//             _toolsItem(context, Icons.score, 'Score Board'),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ToolsPage extends StatelessWidget {
//   const ToolsPage({super.key});
//     @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF2B2B2B),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: const ToolsSection(),
//           ),
//       ),
//     );
//   }
// }