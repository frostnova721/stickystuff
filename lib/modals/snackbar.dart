import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, { int duration = 2}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: duration),
    ),
  );
}
