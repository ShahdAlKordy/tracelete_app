import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _currentQuestion;
  String? _answer;
  String? _confirmationResponse;
  int _currentQuestionIndex = 0;
  List<String> _allQuestions = [
    'How do I pair my bracelet with the app?',
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
    'How do I restart the bracelet?',
    'What is the range of the bracelet?',
    'Where can I find the bracelet\'s serial number?',
  ];
  final Map<String, String> _answersMap = {
    'How do I pair my bracelet with the app?':
        'Open the app and go to the "Pair Bracelet" section in the settings. Follow the on-screen instructions and ensure Bluetooth is enabled on your phone.',
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
    'How do I restart the bracelet?':
        'To restart the bracelet, press and hold the power button for 5-7 seconds until it turns off and then turns back on.',
    'What is the range of the bracelet?':
        'The typical Bluetooth range for the bracelet is around 10-15 meters in open areas. Obstructions may reduce this range.',
    'Where can I find the bracelet\'s serial number?':
        'The serial number is usually printed on the back of the bracelet or on the packaging it came in. You might also find it in the app settings under "Bracelet Info".',
  };
  int _questionsPerPage = 3;

  List<String> get _currentBatchOfQuestions {
    int startIndex = _currentQuestionIndex * _questionsPerPage;
    int endIndex = startIndex + _questionsPerPage;
    if (startIndex < _allQuestions.length) {
      return _allQuestions.sublist(startIndex,
          endIndex > _allQuestions.length ? _allQuestions.length : endIndex);
    }
    return [];
  }

  void _askQuestion(String question) {
    setState(() {
      _currentQuestion = question;
      _answer = _answersMap[question];
      _confirmationResponse = null;
    });
  }

  void _handleConfirmation(bool isHelpful) {
    setState(() {
      _confirmationResponse = isHelpful ? 'Yes' : 'No';
      if (!isHelpful) {
        _currentQuestionIndex = 0; // Go back to the first batch
        _currentQuestion = null;
        _answer = null;
      }
    });
  }

  Widget _buildQuestionBubble(String question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                _askQuestion(question);
              },
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  question,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection() {
    if (_currentQuestion != null && _answer != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _answer!,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _handleConfirmation(true),
                  child: const Text('Yes'),
                ),
                ElevatedButton(
                  onPressed: () => _handleConfirmation(false),
                  child: const Text('No'),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  Widget _buildMoreButton() {
    if (_currentQuestionIndex * _questionsPerPage + _questionsPerPage <
        _allQuestions.length) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentQuestionIndex++;
              });
            },
            child: const Text(
              'More Questions',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildFinalMessage() {
    if (_confirmationResponse == 'Yes') {
      return const Padding(
        padding: EdgeInsets.all(6.0),
        child: Center(
          child: Text(
            'Glad I could help! Do you have any other questions?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
                fontSize: 18),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context); // This line makes the back arrow work
              },
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(
              width: 10,
            ),
            const Text(
              'Tracelet Chat',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Hello! How can I help you today?',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            ..._currentBatchOfQuestions
                .map((question) => _buildQuestionBubble(question)),
            _buildMoreButton(),
            _buildAnswerSection(),
            _buildFinalMessage(),
          ],
        ),
      ),
    );
  }
}
