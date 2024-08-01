import 'dart:developer';

import 'package:chat_as/api/apis.dart';
import 'package:chat_as/main.dart';
import 'package:chat_as/screen/auth/login_screen.dart';
import 'package:chat_as/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => MyWidgetState();
}

class MyWidgetState extends State<SplashScreen> {

  

  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(seconds: 2),(){
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: Colors.white,statusBarColor: Colors.white));
      if(APIs.auth.currentUser!=null){
        log('\nUser:${APIs.auth.currentUser}');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const HomeScreen()));
        
      }
      else{
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const LoginScreen()));
      }
      
    });
  }

  @override
  Widget build(BuildContext context) {
    mq=MediaQuery.of(context).size;
    return  Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to Chat'),
        ),
        body: Stack(children: [
          Positioned(
            top: mq.height*.15,
            right: mq.width*.25,
            width: mq.width*.5,
            child: Image.asset('images/779461.png')),
          Positioned(
            bottom: mq.height*.15,
            width: mq.width,
            child: const Text('Made by elson (BCA)',textAlign: TextAlign.center,style: TextStyle(fontSize: 15,color: Colors.black87,letterSpacing: .5),)),
        ]),
    );
  }
}