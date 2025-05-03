import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';

class AddBraceletDialog extends StatefulWidget {
  @override
  _AddBraceletDialogState createState() => _AddBraceletDialogState();
}

class _AddBraceletDialogState extends State<AddBraceletDialog> {
  final TextEditingController braceletIdController = TextEditingController();
  final TextEditingController ownerNumberController = TextEditingController();
  bool isLoading = false;
  bool isRequestSent = false;

  @override
  void dispose() {
    braceletIdController.dispose();
    ownerNumberController.dispose();
    super.dispose();
  }

  void _handleSendRequest() {
    // Validate fields
    if (braceletIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a bracelet ID')),
      );
      return;
    }

    setState(() {
      isRequestSent = true;
    });
    
    // Simulate request process
    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });
      
      // Simulate connection process
      Future.delayed(Duration(seconds: 3), () {
        if (!mounted) return;
        
        final bracelet = BraceletModel(
          id: braceletIdController.text,
          name: 'Bracelet ${DateTime.now().millisecondsSinceEpoch}',
        );
        
        Navigator.of(context).pop(bracelet);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connect New Bracelet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              if (isLoading)
                Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting...'),
                  ],
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: braceletIdController,
                      decoration: InputDecoration(
                        labelText: 'Bracelet ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: ownerNumberController,
                      decoration: InputDecoration(
                        labelText: 'Owner Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLoading) 
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                  SizedBox(width: 8),
                  if (!isLoading)
                    ElevatedButton(
                      onPressed: isRequestSent ? null : _handleSendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff243561),
                      ),
                      child: Text(
                        isRequestSent ? 'Request Sent' : 'Send Request',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}