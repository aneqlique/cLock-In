import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// class AppConstants {
//   static const String appName = "ClockIn";
//   static const String apiBaseUrl = "http://localhost:3000/api";
//   static const String cloudinaryBaseUrl = "https://res.cloudinary.com";
// }

// const Color PRIMARY = Color(0xFF36261C);
// const Color WHITE = Color(0xFFFFFFFF);

// final String host = ((dotenv.env['HOST']?.isNotEmpty == true ? dotenv.env['HOST']! : 'http://localhost:3000'))
//     .replaceAll(RegExp(r"\s+"), '') // remove all whitespace
//     .replaceAll(RegExp(r"/+$"), ''); // remove trailing slashes
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// const Color PRIMARY = Color(0xFF36261C);
// const Color WHITE = Color(0xFFFFFFFF);

final String host = ((dotenv.env['HOST'] ?? ''))
    .replaceAll(RegExp(r"\s+"), '') // remove all whitespace
    .replaceAll(RegExp(r"/+$"), ''); // remove trailing slashes