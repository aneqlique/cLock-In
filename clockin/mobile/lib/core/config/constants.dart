import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String host = ((dotenv.env['HOST'] ?? ''))
    .replaceAll(RegExp(r"\s+"), '') // remove all whitespace
    .replaceAll(RegExp(r"/+$"), ''); // remove trailing slashes