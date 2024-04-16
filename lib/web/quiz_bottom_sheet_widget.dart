import 'package:flutter/material.dart';
import 'package:realtime_quiz_app/model/problem.dart';
import 'package:realtime_quiz_app/model/quiz.dart';

class QuizBottomSheetWidget extends StatefulWidget {
  const QuizBottomSheetWidget({super.key});

  @override
  State<QuizBottomSheetWidget> createState() => _QuizBottomSheetWidgetState();
}

class _QuizBottomSheetWidgetState extends State<QuizBottomSheetWidget> {
  List<ProblemManager> problemItmes = [];

  ProblemManager? selectedAnswer;
  TextEditingController titleTEC = TextEditingController();

  addOption() {
    problemItmes.add(ProblemManager(
      index: problemItmes.length,
      textEditingController: TextEditingController(),
    ));
    setState(() {});
  }

  removeOption(int index) {
    problemItmes.removeAt(index);
    setState(() {});
  }

  @override
  void dispose() {
    titleTEC.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('퀴즈문제 출제하기'),
          TextField(
            decoration: InputDecoration(
              hintText: '문제를 입력해 주세요',
            ),
            controller: titleTEC,
          ),
          Text('문제에 대한 선택지'),
          Expanded(
            child: ListView.builder(
              itemCount: problemItmes.length,
              itemBuilder: (context, index) {
                final item = problemItmes[index];
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: item.textEditingController,
                        decoration: InputDecoration(hintText: '선택지 입력'),
                        onSubmitted: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          removeOption(index);
                        });
                      },
                      icon: Icon(
                        Icons.clear,
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          const Text('정답 선택'),
          DropdownButton<ProblemManager>(
            value: selectedAnswer,
            items: problemItmes
                .map(
                  (e) => DropdownMenuItem<ProblemManager>(
                    value: e,
                    child: Text(e.textEditingController.text),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedAnswer = value;
              });
            },
          ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () {
                  addOption();
                },
                child: Text('선택지 추가'),
              ),
              TextButton(
                child: Text('완료'),
                onPressed: () {
                  //문제의 정답이 없는 경우
                  if (titleTEC.text.isEmpty) {
                    return;
                  }
                  if (problemItmes.isEmpty) {
                    return;
                  }
                  // 선택지가 없는 경우
                  // 정답 선택이 없는 경우
                  if (selectedAnswer == null) {
                    return;
                  }
                  // 위에 경우에는 리턴

                  // modal page 에서 넘겨주는 과정

                  final quiz = QuizManager(
                    problems: problemItmes,
                    title: titleTEC.text.trim(),
                    answer: selectedAnswer,
                  );
                  Navigator.of(context).pop<QuizManager>(quiz);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
