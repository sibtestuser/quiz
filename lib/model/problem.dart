import 'package:flutter/material.dart';

//출제자용 문제 데이타 모델
class ProblemManager {
  int? index;
  TextEditingController textEditingController;

  ProblemManager({
    required this.index,
    required this.textEditingController,
  });
}

//문제에 대한 모델
class Problems {
  int? answerIndex;
  String? answer;
  List<String>? options;
  String? title;

  Problems({this.answerIndex, this.answer, this.options, this.title});

  Problems.fromJson(Map<String, dynamic> json) {
    answer = json['answer'];
    answerIndex = json['answerIndex'];
    options = json['options'].cast<String>();
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['answerIndex'] = answerIndex;
    data['answer'] = answer;
    data['options'] = options;
    data['title'] = title;

    return data;
  }
}
