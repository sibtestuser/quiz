import 'dart:async';
import 'dart:convert';
//import 'dart:ffi';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:realtime_quiz_app/main.dart';
import 'package:realtime_quiz_app/model/problem.dart';
import 'package:realtime_quiz_app/model/quiz.dart';

class QuizPage extends StatefulWidget {
  final String quizRef;
  final String name;
  final String uid;
  final String code;
  const QuizPage({super.key, required this.quizRef, required this.name, required this.uid, required this.code});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  DatabaseReference? quizStateRef;
  List<Problems> ProblemSets = [];
  List<Map<String, int>> problemTriggers = [];

  String quizStatePath = 'quiz_state';
  String quizDetailPath = 'quiz_detail';

  fetchQuizInformations() async {
    quizStateRef = database?.ref('${quizStatePath}/${widget.quizRef}');
    final quizDetailRef = database?.ref(quizDetailPath + '/' + widget.quizRef);
    await quizDetailRef?.get().then((value) {
      final obj = jsonDecode(jsonEncode(value.value));
      final quizDetail = QuizDetail.fromJson(obj);

      quizDetail.problems?.forEach((element) {
        ProblemSets.add(element);
      });
      quizStateRef?.child('triggers').get().then((value) {
        for (var element in value.children) {
          final trigger = jsonDecode(jsonEncode(element.value)) as Map<String, int>;
          problemTriggers.add({'start': trigger['start']!, 'end': trigger['end']!});
        }
      });

      quizStateRef?.child('user').push().set({
        'uid': widget.uid,
        'name': widget.name,
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchQuizInformations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name}  (코드 : ${widget.code}) '),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('참가자 뷰'),
                    Expanded(
                      child: StreamBuilder(
                        stream: quizStateRef?.child('/user').onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final items = snapshot.data?.snapshot.children.toList() ?? [];
                            return ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index].value as Map;
                                return ListTile(
                                  title: Text('닉네임 : ${item['name']}'),
                                  subtitle: Text('ID : ${item['uid']}'),
                                );
                              },
                            );
                          }
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: CircularProgressIndicator(),
                              ),
                              Text('참가자 확인 중'),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    const Text('퀴즈 시작 상태'),
                    Expanded(
                        child: StreamBuilder(
                      stream: quizStateRef?.child("state").onValue,
                      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                        if (snapshot.hasData) {
                          print(snapshot.data?.snapshot.value);
                          final state = snapshot.data?.snapshot.value as bool;
                          return Center(
                            child: Column(
                              children: [
                                Text(
                                  switch (state) { true => "시작!", false => "대기중" },
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    )),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: StreamBuilder(
                stream: quizStateRef?.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    int currentIndex = 0;
                    Map snapshotData = snapshot.data?.snapshot.value as Map;
                    final state = snapshotData['state'] as bool;
                    if (snapshotData.containsKey('current')) {
                      currentIndex = snapshotData['current'] as int;
                    }
                    problemTriggers.clear();
                    if (snapshotData.containsKey('triggers')) {
                      for (var elemnent in snapshotData['triggers']) {
                        final trigger = elemnent as Map;
                        problemTriggers.add({
                          'start': trigger['start'],
                          'end': trigger['end'],
                        });
                      }
                    }
                    if (state) {
                      if (currentIndex < ProblemSets.length) {
                        //문제풀이 중
                        return Container(
                          color: Colors.white,
                          child: Container(), //다음 문제
                        );
                      } else {
                        //문제풀이 종료
                        return Container(); //순위 계산
                      }
                    }
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemSolveWidget extends StatefulWidget {
  final DatabaseReference ref;
  final Problems problems;
  final String uid;
  final String name;
  final int startTime;
  final int endTime;
  final int index;

  const _ProblemSolveWidget(
      {super.key,
      required this.ref,
      required this.problems,
      required this.uid,
      required this.name,
      required this.startTime,
      required this.endTime,
      required this.index});

  @override
  State<_ProblemSolveWidget> createState() => __ProblemSolveWidgetState();
}

class __ProblemSolveWidgetState extends State<_ProblemSolveWidget> {
  Timer? timer;

  int leftTime = 0;
  int readyTime = 0;

  bool isSatart = false;
  bool isSubilt = false;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    timer?.cancel();
  }

  refresh() {
    if (context.mounted) {
      setState(() {});
    }
  }

  Future periodicTask() async {
    final startTime = DateTime.fromMillisecondsSinceEpoch(widget.startTime);
    final endTime = DateTime.fromMillisecondsSinceEpoch(widget.endTime);

    timer ??= Timer.periodic(
      Duration(seconds: 1),
      (t) {
        DateTime nowDateTime = DateTime.now();
        final sDiff = nowDateTime.difference(startTime);
        final eDiff = endTime.difference(nowDateTime);

        readyTime = sDiff.inSeconds;
        leftTime = eDiff.inSeconds;

        if (sDiff.inSeconds >= 0) {
          //문제풀이가 시작이 되면
          isSatart = true;
        }

        if (eDiff.inSeconds <= 0) {
          //문제 풀이가 종료
          int nextIndex = widget.index + 1;
          widget.ref.child('current').set(nextIndex);
          timer?.cancel();
          timer = null;
          isSatart = false;
          isSubilt = false;
        }
        refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    periodicTask();
    return switch (isSatart) {
      true => Column(
          children: [
            Text(
              '문제시작',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              '${widget.problems.title}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Expanded(
              child: Container(),
            ),
            Text(
              '${leftTime}초 ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 42),
            ),
          ],
        ),
      false => Container(),
    };
  }
}
