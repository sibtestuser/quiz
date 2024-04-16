import 'package:realtime_quiz_app/model/problem.dart';

class QuizManager {
  List<ProblemManager>? problems; //보기의 목록들
  String? title; // 문제 타이틀
  ProblemManager? answer;

  QuizManager({required this.problems, required this.title, required this.answer});
}

class QuizDetail {
  String? code;
  List<Problems>? problems;

  QuizDetail(this.code, this.problems);

  QuizDetail.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    if (json['problems'] != null) {
      problems = [];
      json['problems'].forEach((v) {
        problems?.add(Problems.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['code'] = code;
    if (problems != null) {
      data['problems'] = problems!.map((e) => e.toJson()).toList();
    }

    return data;
  }
}

class Quiz {
  String? code;
  String? generatedTime;
  String? quizDetailRef;
  int? timeStamp;
  String? uid;

  Quiz({this.code, this.generatedTime, this.quizDetailRef, this.timeStamp, this.uid});

  Quiz.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    generatedTime = json['generatedTime'];
    quizDetailRef = json['quizDetailRef'];
    timeStamp = json['timeStamp'];
    uid = json['uid'];
  }
}
