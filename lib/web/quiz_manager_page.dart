import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:realtime_quiz_app/main.dart';
import 'package:realtime_quiz_app/model/quiz.dart';
import 'package:realtime_quiz_app/web/quiz_bottom_sheet_widget.dart';

class QuizManagerPage extends StatefulWidget {
  const QuizManagerPage({super.key});

  @override
  State<QuizManagerPage> createState() => _QuizManagerPageState();
}

class _QuizManagerPageState extends State<QuizManagerPage> {
  String? uid;
  List<QuizManager> quizItems = []; //퀴즈 문제 목록

  List<Quiz> quizList = []; //퀴즈 출제 목록
  //퀴즈 출제 목록

  StreamSubscription? streamSubscription;
  int? selectedIndex;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    signInAnonymously();
    streamQuizzes();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    // TODO: implement dispose
    super.dispose();
  }

//익명 로그인 정보
  signInAnonymously() {
    FirebaseAuth.instance.signInAnonymously().then((value) {
      setSate() {
        uid = value.user?.uid ?? '';
      }
    });
  }

  generateQuiz() async {
    if (quizItems.isEmpty) {
      return;
    }
    final pinCode = Random().nextInt(999999).toString().padLeft(6);
    final quizRef = database!.ref('quiz');
    final quizDerailRef = database!.ref('quiz_detail');
    final quizStateRef = database!.ref('quiz_state');
    final newQuizDetailRef = quizDerailRef.push(); //새 키가 generate 됨

    newQuizDetailRef.set({
      'code': pinCode,
      'problems': quizItems.map(
        (e) {
          return {
            'title': e.title,
            'options': e.problems?.map(
              (e2) {
                return e2.textEditingController.text.trim();
              },
            ).toList(),
            'answerIndex': e.answer?.index,
            'answer': e.answer?.textEditingController.text.trim(),
          };
        },
      ).toList(),
    });

    await quizStateRef.child('${newQuizDetailRef.key}').set({
      'quizDetail': newQuizDetailRef.key,
      'user': [],
      'state': false,
      'score': [],
      'solve': [{}],
    });

    final newQuizRef = quizRef.push();
    await newQuizRef.set({
      'code': pinCode,
      'uid': uid,
      'generatedTime': DateTime.now().toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'quizDetailRef': newQuizDetailRef.key,
    });
  }

  streamQuizzes() {
    database?.ref('quiz').onValue.listen((event) {
      final data = event.snapshot.children;
      quizList.clear();
      for (var element in data) {
        quizList.add(Quiz.fromJson(element.value as Map<String, dynamic>));
      }
      setState(() {});
    });
  }

  startQuiz(Quiz item, int index) async {
    final ref = await database?.ref('quiz_state/${item.quizDetailRef}/state').get();
    final currentState = ref?.value as bool;
    if (!currentState) {
      final quizDetailRef = await database?.ref('quiz_detail/${item.quizDetailRef}').get();
      final problemCount = quizDetailRef?.child('problems').children.length ?? 0;
      DateTime nowDatetime = DateTime.now();
      List<Map> triggerTimes = [];
      int solveTime = 5;
      for (var i = 0; i < problemCount; i++) {
        final startTime = nowDatetime.add(Duration(seconds: 5 + (i * solveTime)));
        final endTime = startTime.add(const Duration(seconds: 5));
        triggerTimes.add({'start': startTime.microsecondsSinceEpoch, 'end': endTime.millisecondsSinceEpoch});
        nowDatetime = endTime;
      }
      //비동기 일대는 mounted check 해줘
      if (context.mounted) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: const Text('퀴즈를 시작할까요?'),
                title: const Text('안내'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await database?.ref('quiz_state/${item.quizDetailRef}').update({
                        'state': true,
                        'current': 0,
                        'triggers': triggerTimes,
                      });
                      setState(() {
                        selectedIndex = index;
                      });

                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text('시작'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // 이건 취소
                      // await database?.ref('quiz_state/${item.quizDetailRef}').update({
                      //   'state': false,
                      //   'current': 0,
                      //   'triggers': triggerTimes,
                      // });
                      // setState(() {
                      //   selectedIndex = null;
                      // });

                      // if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text('취소'),
                  ),
                ],
              );
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '퀴즈 출제하기 (출제자용)',
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '출제하기'),
                Tab(text: '퀴즈목록'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: quizItems.length,
                          itemBuilder: (context, index) {
                            return ExpansionTile(
                              title: Text('문제 ${index + 1} 번 => ${quizItems[index].title}  ' ?? '문제 타이틀이 없습니다'),
                              children: [
                                ...quizItems[index].problems?.map(
                                      (e) {
                                        return ListTile(
                                          title: Text(
                                            e.textEditingController.text ?? '답 예제가 없어요',
                                          ),
                                        );
                                      },
                                    ).toList() ??
                                    [],
                              ],
                            );
                          },
                        ),
                      ),
                      MaterialButton(
                        onPressed: () {
                          //Todo 퀴즈 생성 및 핀코드 생성 로직 추가
                          generateQuiz();
                        },
                        height: 72,
                        color: Colors.indigo,
                        child: const Text(
                          '제출 및 핀코드 생성',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  ListView.builder(
                    itemCount: quizList.length,
                    itemBuilder: (context, index) {
                      final item = quizList[index];
                      return ListTile(
                        title: Text('code : ${item.code} '),
                        subtitle: RichText(
                          text: TextSpan(text: '${item.quizDetailRef}' + (selectedIndex == index ? ' <시작됨 >' : '')),
                        ),
                        onTap: () {
                          //Todo 퀴즈를 시작
                          startQuiz(item, index);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //문제 출제를 위한 모달을 띄우기
          final quiz = await showModalBottomSheet(
            context: context,
            builder: (constext) {
              return QuizBottomSheetWidget();
            },
          );
          setState(() {
            if (quiz != null) quizItems.add(quiz);
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
