import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:realtime_quiz_app/main.dart';
import 'package:realtime_quiz_app/quiz_app/quiz_app.dart';

class PinCodePage extends StatefulWidget {
  const PinCodePage({super.key});

  @override
  State<PinCodePage> createState() => _PinCodePageState();
}

class _PinCodePageState extends State<PinCodePage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  TextEditingController pinTEC = TextEditingController();
  TextEditingController nickTEC = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? uid;
  //핀코드 중복
  final codeItems = [];
  final availableItems = [];
  signInAnonymously() {
    auth.signInAnonymously().then((value) {
      uid = value.user?.uid;
    }).catchError((error) {
      print('Error signing in anonymously: $error');
    });
  }

  Future<bool> findPinCode(String code) async {
    final quizRef = database?.ref('quiz');
    final result = await quizRef?.get();
    codeItems.clear();
    availableItems.clear();
    for (var element in result!.children) {
      //final data = element.value as Map<String, dynamic>;
      final data = jsonDecode(jsonEncode(element.value)) as Map<String, dynamic>;
      DateTime nowDate = DateTime.now();
      DateTime generatedTime = DateTime.parse(data['generatedTime']);
      if (nowDate.difference(generatedTime).inDays < 1) {
        availableItems.add(data['quizDetailRef']);
        if (data.containsValue(code)) {
          codeItems.add(data['quizDetailRef']);
        }
      }
    }

    return codeItems.isEmpty ? false : true;
  }

  Future<bool> findNickName(String nickName) async {
    //final nickNameRef = database?.ref('quiz_state/');
    //   final result = await nickNameRef?.get();
    final nameList = [];
    // if (result == null) return false;
    for (var quiz in availableItems) {
      final nickNameRef = database?.ref('quiz_state/$quiz/user');
      final result = await nickNameRef?.get();
      if (result?.value != null) {
        final item = result?.value as Map;

        item.forEach((key, value) {
          // print('naem --');
          // print(item[key]['name']);
          nameList.add(item[key]['name']);
        });
        //nameList.add(item['value']['name']);
      }
    }

    if (nameList.contains(nickName)) {
      print('같은 닉네임 존재');
      return true;
    }
    return false;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    signInAnonymously();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('입장 코드 입력'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: pinTEC,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '입장코드를 입력해주세요',
                        labelText: 'Pin Code',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'pincode 를 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      controller: nickTEC,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '닉네임을 입력해주세요',
                        labelText: 'Nick Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    MaterialButton(
                      height: 72,
                      color: Colors.indigo,
                      onPressed: () async {
                        final validation = _formKey.currentState?.validate();

                        final result = await findPinCode(pinTEC.text.trim());
                        // final nicknamecheck - findNickName(checkSamekName);
                        if (result && context.mounted && validation!) {
                          final checkSamekName = await findNickName(
                            nickTEC.text.trim(),
                          );
                          print('코드가 존재함');
                          if (checkSamekName) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('중복된 닉네임입니다')),
                            );
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                              return QuizPage(
                                quizRef: codeItems.first,
                                name: nickTEC.text.trim(),
                                uid: uid ?? 'Unkown User',
                                code: pinTEC.text.trim(),
                              );
                            }));
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('등록된 핀코드가 없습니다')),
                            );
                          }
                        }
                        //await findPinCode('1111');
                      },
                      child: const Text(
                        '입장하기',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
