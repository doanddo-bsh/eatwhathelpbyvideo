import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'component/firebase_options.dart';
import 'page/mainPage.dart';

void main() async {
  // 비동기 되게 하는 문장
  WidgetsFlutterBinding.ensureInitialized();

  // firebase init
  await Firebase.initializeApp(
    // to create lib/firebase_options.dart
    options: DefaultFirebaseOptions.currentPlatform,
  ); // <- firebase add init setting

  // run app
  runApp(const MyApp());
}

// MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eatwhathelpbyvideo',
      debugShowCheckedModeBanner: false, // 디버그 배너삭제
      theme: ThemeData(
          appBarTheme: AppBarTheme( // appbar 색 변경
            color: const Color(0xFF151026),
          )),
      home: MyHomePage(),
    );
  }
}
