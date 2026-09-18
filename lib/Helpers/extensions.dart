import 'package:flutter/material.dart';

extension Extra on TimeOfDay {

  String formatted(){
    return '${hour}h${minute.toString().padLeft(2, '0')}'; // adicionando dois zeros ex: 12:00
  }

  int toMinutes() => hour*60 + minute;

}