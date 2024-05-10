import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, { int duration = 2, bool removePrevious = false}) {
  if(removePrevious) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: duration),
    ),
  );
}
