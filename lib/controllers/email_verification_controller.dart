import 'dart:async';
import 'package:flutter/material.dart';

class EmailVerificationLogic extends ChangeNotifier {
  late Timer _timer;
  int _seconds = 60;

  int get seconds => _seconds;

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void resetTimer() {
    _seconds = 60;
    startTimer();
    notifyListeners();
  }

  void disposeTimer() {
    _timer.cancel();
  }
}
