import 'package:flutter/material.dart';
import 'mainpage.dart';

class SelectDoctor extends StatefulWidget {
  final String userId;

  SelectDoctor({ required this.userId});

  @override
  SelectDoctorState createState() => SelectDoctorState();
}

class SelectDoctorState extends State<SelectDoctor> {
  String username = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
              // Navigate back to the main page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainPage(userId: widget.userId),
                ),
              );
            } 
          ),
        title: Image.asset(
          'assets/cliniclogo.jpg', 
          height: 60,
        ),
        centerTitle: true,
      ),
      
    );
  }
}
