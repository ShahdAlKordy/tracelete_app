import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';

class OTPInput extends StatefulWidget {
  final int length;
  final Function(String) onChanged;

  const OTPInput({super.key, this.length = 6, required this.onChanged});

  @override
  _OTPInputState createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (index) => TextEditingController());
    focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void updateOTP() {
    String otp = controllers.map((controller) => controller.text).join();
    widget.onChanged(otp);
    print("🔢 Current OTP: $otp");
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return Container(
          width: screenWidth * 0.12,
          height: screenHeight * 0.07,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: "",
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < widget.length - 1) {
                    FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                  }
                } else {
                  if (index > 0) {
                    FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                  }
                }
                updateOTP();
              },
            ),
          ),
        );
      }),
    );
  }
}
