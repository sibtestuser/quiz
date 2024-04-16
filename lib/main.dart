import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realtime_quiz_app/firebase_options.dart';

import 'package:realtime_quiz_app/quiz_app/pin_code_page.dart';
import 'package:realtime_quiz_app/web/quiz_manager_page.dart';

FirebaseDatabase? database;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  String host = '';
  String baseUrl = '';

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      host = 'http://10.0.0.2:9000';
      baseUrl = '127.0.0.1';
    } else {
      host = 'http://localhost:9000';
      baseUrl = '127.0.0.1';
    }
  } catch (e) {
    print(e.toString());
  }

  database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    //에뮬레이터에서  realtime Database 에서 default 붙은 거 2번째거에서 ns 이후거 (주소창에 database 다음부터)
    //에뮬레이터에 database 기본 포트가 9000
    databaseURL: '$host?ns=realtime-quiz-app-1aed7-default-rtdb',
  );

  // 만약 진짜 firebase database 에 접근하려면
  // database = FirebaseDatabase.instance; 로 해도 돼

  await FirebaseAuth.instance.useAuthEmulator(baseUrl, 9099);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return MaterialApp(
        title: '실시가 퀴즈앱',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const PinCodePage(),
      );
    }
    return MaterialApp(
      title: '실시간 퀴즈앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QuizManagerPage(),
    );
  }
}
