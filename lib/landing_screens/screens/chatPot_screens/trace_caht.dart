import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';

class SupportScreen extends StatefulWidget {
  final String? userName;
  const SupportScreen({super.key, this.userName});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _currentQuestion;
  String? _answer;
  String? _confirmationResponse;
  int _currentQuestionIndex = 0;
  bool _isWaitingForBraceletSelection = false;
  List<BraceletModel> _activeBracelets = [];

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _allQuestions = [
    'How do I pair my bracelet?',
    'Show me my bracelet',
    'Where is my bracelet?',
    'How do I set up a safe zone?',
    'What notifications will I receive?',
    'What if the app is not tracking my location accurately?',
    'How can I view the location history?',
    'What does the battery indicator on the app mean?',
    'Can I set up geofences or safe zones?',
    'What happens if the bracelet loses connection?',
    'How do I change the monitoring settings?',
    'Is my location data secure?',
    'Can multiple people monitor one bracelet?',
    'What are the alert notifications for?',
    'How do I update the app?',
    'What if I forget my app password?',
  ];

  final Map<String, String> _answersMap = {
    'How do I pair my bracelet?':
        'Open the app and go to the "Pair Bracelet" section in the settings. Follow the on-screen instructions and ensure Bluetooth is enabled on your phone.',
    'Show me my bracelet':
        'I will show you the current location of your bracelet on the map.',
    'Where is my bracelet?':
        'You can find your bracelet location in the main dashboard. The map will show the current location with a blue dot.',
    'How do I set up a safe zone?':
        'Go to Settings > Safe Zones, then tap "Add Zone" and draw the area on the map where you want to set up the safe zone.',
    'What notifications will I receive?':
        'You will receive notifications for: entering/exiting safe zones, low battery alerts, connection status, and emergency alerts.',
    'What if the app is not tracking my location accurately?':
        'Ensure that location services are enabled on your phone and that the app has the necessary permissions. Check if the bracelet is securely connected.',
    'How can I view the location history?':
        'Navigate to the "Location History" section in the app menu. You will be able to see the past tracking data.',
    'What does the battery indicator on the app mean?':
        'The battery indicator shows the current battery level of your smart bracelet. A low battery may affect performance.',
    'Can I set up geofences or safe zones?':
        'Yes, you can set up geofences in the app settings. You will receive notifications when the bracelet enters or exits these zones.',
    'What happens if the bracelet loses connection?':
        'If the bracelet loses connection, the app will notify you. Location data will be stored on the bracelet and synced once the connection is restored.',
    'How do I change the monitoring settings?':
        'You can adjust the monitoring frequency and other settings in the "Monitoring Settings" section of the app.',
    'Is my location data secure?':
        'Yes, your location data is encrypted and securely stored. We prioritize your privacy and data protection.',
    'Can multiple people monitor one bracelet?':
        'Currently, only one account can actively monitor a single bracelet for security and privacy reasons.',
    'What are the alert notifications for?':
        'Alert notifications can be set up for various events, such as entering/exiting geofences, low battery, or bracelet disconnection.',
    'How do I update the app?':
        'You can update the app through the Google Play Store (Android) or the App Store (iOS).',
    'What if I forget my app password?':
        'You can reset your password by clicking on the "Forgot Password" link on the login screen and following the instructions.',
  };

  @override
  void initState() {
    super.initState();
    _loadActiveBracelets();
  }

  Future<void> _loadActiveBracelets() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final QuerySnapshot braceletsSnapshot = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .where("is_active", isEqualTo: true)
          .get();

      final List<BraceletModel> loadedBracelets =
          braceletsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BraceletModel(
          id: data['bracelet_id'] ?? doc.id,
          name: data['name'] ?? 'Bracelet ${doc.id}',
        );
      }).toList();

      setState(() {
        _activeBracelets = loadedBracelets;
      });
    } catch (e) {
      print("Error loading bracelets: $e");
    }
  }

  Future<String?> _getUserProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('profile_image_path');

      if (savedPath != null && File(savedPath).existsSync()) {
        return savedPath;
      }
    } catch (e) {
      print("Error loading user profile image: $e");
    }
    return null;
  }

  Widget _buildUserProfileImage(String? imagePath) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultUserIcon();
        },
      );
    } else {
      return _buildDefaultUserIcon();
    }
  }

  Widget _buildDefaultUserIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  final int _questionsPerPage = 4;
  final List<Widget> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();

  List<String> get _currentBatchOfQuestions {
    int startIndex = _currentQuestionIndex * _questionsPerPage;
    int endIndex = startIndex + _questionsPerPage;
    if (startIndex < _allQuestions.length) {
      return _allQuestions.sublist(startIndex,
          endIndex > _allQuestions.length ? _allQuestions.length : endIndex);
    }
    return [];
  }

  void _askQuestion(String question) async {
    setState(() {
      _chatMessages.add(_buildUserMessage(question));
    });

    if (question == 'Show me my bracelet') {
      await _handleShowBraceletRequest();
    } else {
      String answer = _answersMap[question] ??
          "I'm sorry, I don't have an answer for that question.";
      setState(() {
        _chatMessages.add(_buildBotMessage(answer));
        _currentQuestion = question;
        _answer = answer;
        _confirmationResponse = null;
      });
    }
  }

  Future<void> _handleShowBraceletRequest() async {
    if (_activeBracelets.isEmpty) {
      setState(() {
        _chatMessages.add(_buildBotMessage(
            "You don't have any active bracelets configured. Please add a bracelet first."));
      });
      return;
    }

    if (_activeBracelets.length == 1) {
      await _showBraceletLocation(_activeBracelets.first);
    } else {
      setState(() {
        _isWaitingForBraceletSelection = true;
        _chatMessages.add(_buildBotMessage(
            "You have multiple bracelets. Please select which bracelet you want to see:"));
        _chatMessages.add(_buildBraceletSelectionButtons());
      });
    }
  }

  Widget _buildBraceletSelectionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: _activeBracelets.map((bracelet) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectBracelet(bracelet),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  bracelet.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _selectBracelet(BraceletModel bracelet) async {
    setState(() {
      _isWaitingForBraceletSelection = false;
      _chatMessages.add(_buildUserMessage(bracelet.name));
    });

    await _showBraceletLocation(bracelet);
  }

  Future<void> _showBraceletLocation(BraceletModel bracelet) async {
    try {
      // Check if bracelet is connected
      final connectedSnapshot = await dbRef
          .child("bracelets/${bracelet.id}/user_info/connected")
          .get();

      if (!connectedSnapshot.exists || connectedSnapshot.value != true) {
        setState(() {
          _chatMessages.add(_buildBotMessage(
              "❌ ${bracelet.name} is currently disconnected. Please ensure the bracelet is powered on and within range."));
        });
        return;
      }

      // Get bracelet location
      final locationSnapshot =
          await dbRef.child("bracelets/${bracelet.id}/location").get();

      if (!locationSnapshot.exists) {
        setState(() {
          _chatMessages.add(_buildBotMessage(
              "⚠️ Location data for ${bracelet.name} is not available at the moment."));
        });
        return;
      }

      final data = locationSnapshot.value as Map;
      final lat = double.tryParse(data['lat'].toString());
      final lng = double.tryParse(data['lng'].toString());

      if (lat == null || lng == null) {
        setState(() {
          _chatMessages.add(_buildBotMessage(
              "⚠️ Invalid location data for ${bracelet.name}."));
        });
        return;
      }

      // Create satellite map image URL with higher zoom
      final String mapImageUrl =
          'https://maps.googleapis.com/maps/api/staticmap?'
          'center=$lat,$lng&'
          'zoom=21&' // Increased zoom for closer view
          'size=300x300&'
          'maptype=satellite&'
          'markers=color:red%7Clabel:B%7C$lat,$lng&'
          'key=AIzaSyBzZRaB0KHS2P4g3efFBKYTLGO8gFsSvhk'; // Replace with your actual API key

      setState(() {
        _chatMessages.add(_buildBotMessage(
            "📍 Here's the current location of ${bracelet.name}:"));
        _chatMessages.add(_buildLocationImageMessage(mapImageUrl, lat, lng));
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(_buildBotMessage(
            "❌ Error retrieving location for ${bracelet.name}. Please try again."));
      });
      print("Error getting bracelet location: $e");
    }
  }

  Widget _buildLocationImageMessage(String imageUrl, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🤖',
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Map Preview\nNot Available',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add(_buildUserMessage(message));
      _chatMessages.add(_buildBotMessage(
          "Thank you for your question! For more specific inquiries, please contact us at support@tracelet.com and our team will get back to you shortly."));
    });

    _messageController.clear();
  }

  void _handleSeeMore() {
    setState(() {
      _currentQuestionIndex++;
    });
  }

  void _resetChat() {
    setState(() {
      _chatMessages.clear();
      _currentQuestionIndex = 0;
      _currentQuestion = null;
      _answer = null;
      _confirmationResponse = null;
      _isWaitingForBraceletSelection = false;
    });
  }

  Widget _buildBotMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🤖',
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              margin: const EdgeInsets.only(left: 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
          FutureBuilder<String?>(
            future: _getUserProfileImage(),
            builder: (context, snapshot) {
              return Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(left: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildUserProfileImage(snapshot.data),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionButton(String question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ElevatedButton(
        onPressed: () => _askQuestion(question),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0.5,
          shadowColor: Colors.grey.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSeeMoreButton() {
    if (_currentQuestionIndex * _questionsPerPage + _questionsPerPage <
        _allQuestions.length) {
      return TextButton(
        onPressed: _handleSeeMore,
        child: Text(
          'See more',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: Color(0xFF4A90E2), size: 24),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracelet Chat',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '● Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.black, size: 24),
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            color: Colors.white,
            child: Column(
              children: [
                ..._currentBatchOfQuestions
                    .map((question) => _buildQuestionButton(question)),
                _buildSeeMoreButton(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return _chatMessages[index];
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Write your message',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
