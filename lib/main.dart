/*
comando cmd para mostrar chave SHA1
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

site para autorizar auth app
https://console.cloud.google.com/
 */

import 'package:chatbasic/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main()async {

  runApp(MyApp());
  await Firebase.initializeApp();
}
class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.blue,
        )
      ),
      home: ChatScreen(),
    );
  }
}
