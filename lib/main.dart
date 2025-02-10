import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import "home.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFood',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poiret',
      ),
      home: BlocProvider(
        create: (context) => NavigationCubit(),
        child: Home(),
      ),
    );
  }
}

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void changePage(int index) => emit(index);
}