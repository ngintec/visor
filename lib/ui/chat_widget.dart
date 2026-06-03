// import 'package:flutter/material.dart';

// class ChatEntry {
//   final String text;
//   final bool isRecognized; // true = speech recognized, false = TTS spoken

//   ChatEntry({required this.text, required this.isRecognized});
// }

// class ChatWidget extends StatelessWidget {
//   final List<ChatEntry> entries;

//   const ChatWidget({super.key, required this.entries});

//   @override
//   Widget build(BuildContext context) {
//     if (entries.isEmpty) return const SizedBox.shrink();

//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: Container(
//         height: 200,
//         color: Colors.black.withAlpha(120),
//         child: ListView.builder(
//           padding: const EdgeInsets.all(8),
//           itemCount: entries.length,
//           itemBuilder: (context, index) {
//             final entry = entries[index];
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 2),
              
//               child: Row(
//                 children: [
//                   Text(
//                     entry.isRecognized ? '🎤 ' : '🔊 ',
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                   Expanded(
//                     child: Text(
//                       entry.text,
//                       style: TextStyle(
//                         color: entry.isRecognized
//                             ? Colors.greenAccent  // speech recognized
//                             : Colors.lightBlueAccent, // TTS spoken
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }