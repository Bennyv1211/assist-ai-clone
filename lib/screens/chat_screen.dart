import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Dio _dio = Dio();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  stt.SpeechToText speech = stt.SpeechToText();
  FlutterTts flutterTts = FlutterTts();
  bool _isLoading = false;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Response response = await _dio.post(
        "http://10.0.2.2:8000/chat/",
        data: {"prompt": text, "user_id": user!.uid},
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      Map<String, dynamic> data = response.data;
      String aiResponse = data["response"];
      String? action = data["action"];

      await flutterTts.speak(aiResponse);

      if (action != null) {
        if (action == "call") {
          _callNumber(data["number"]);
        } else if (action == "set_alarm") {
          _setAlarm(data["hour"], data["minute"]);
        } else if (action == "set_timer") {
          _setTimer(data["minutes"]);
        } else if (action == "send_whatsapp") {
          _sendWhatsAppMessage(data["number"], data["message"]);
        } else if (action == "send_email") {
          _sendEmail(data["recipient"], data["subject"], data["body"]);
        }
      }

      _db.collection("users").doc(user!.uid).collection("chats").add({
        "message": text,
        "response": aiResponse,
        "timestamp": DateTime.now().toIso8601String(),
      });

    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// ✅ **Method to Call a Number**
  void _callNumber(String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: "tel:$number",
    );
    await intent.launch();
  }

  /// ✅ **Method to Set an Alarm**
  void _setAlarm(int hour, int minute) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {'android.intent.extra.alarm.HOUR': hour, 'android.intent.extra.alarm.MINUTES': minute},
    );
    await intent.launch();
  }

  /// ✅ **Method to Set a Timer**
  void _setTimer(int minutes) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: {'android.intent.extra.alarm.LENGTH': minutes * 60},
    );
    await intent.launch();
  }

  /// ✅ **Method to Send WhatsApp Message**
  void _sendWhatsAppMessage(String number, String message) async {
    final intent = AndroidIntent(
      action: "android.intent.action.VIEW",
      data: "https://api.whatsapp.com/send?phone=$number&text=${Uri.encodeComponent(message)}",
      package: "com.whatsapp",
    );
    await intent.launch();
  }

  /// ✅ **Method to Send an Email (Opens Email Client)**
  void _sendEmail(String recipient, String subject, String body) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: recipient,
      queryParameters: {'subject': subject, 'body': body},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      print("Could not launch email client.");
    }
  }

  /// ✅ **Method to Sign Out**
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen())); // ✅ Fixed reference to AuthScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assist AI - Chat"),
        actions: [IconButton(icon: Icon(Icons.exit_to_app), onPressed: _signOut)],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection("users").doc(user!.uid).collection("chats").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return ListTile(
                      title: Text(doc["message"]),
                      subtitle: Text(doc["response"]),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: "Type a message..."))),
                IconButton(icon: Icon(Icons.send), onPressed: () {
                  _sendMessage(_controller.text);
                  _controller.clear();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
