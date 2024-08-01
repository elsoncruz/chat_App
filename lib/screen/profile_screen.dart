
import 'dart:developer';
import 'dart:io';

import 'package:chat_as/api/apis.dart';
import 'package:chat_as/main.dart';
import 'package:chat_as/models/chat_user.dart';
import 'package:chat_as/screen/auth/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../helper/dialogs.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => MyWidgetState();
}

class MyWidgetState extends State<ProfileScreen> {
  final _formkey=GlobalKey<FormState>();
  String? _image;
  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      onTap: ()=>FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ProfileScreen'),
          ),
      
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.redAccent,
              onPressed: () async {
                Dialogs.showProgressBar(context);

                await APIs.updateActiveStatus(false);

                  await APIs.auth.signOut().then((value) async {
                  await GoogleSignIn().signOut().then((value) {
                     Navigator.pop(context);
                     
                     APIs.auth=FirebaseAuth.instance;
      
                     Navigator.pop(context);
      
                     Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>const LoginScreen()));
                  });
                });
                  
            },icon: const Icon(Icons.logout),label: const Text('logout')),
          ),
        //body
        body: Form(
          key: _formkey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width*.05),
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(width: mq.width, height: mq.height*.03),
              Stack(
                children: [
                  _image!=null?
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height *.1),
                    child: Image.file(
                      File(_image!),
                      width: mq.height * .2,
                      height: mq.height * .2,
                      fit: BoxFit.cover))
                  :
                  //image from server
                            ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(mq.height * .1),
                                child: CachedNetworkImage(
                                  width: mq.height * .2,
                                  height: mq.height * .2,
                                  fit: BoxFit.cover,
                                  imageUrl: widget.user.image,
                                  errorWidget: (context, url, error) =>
                                      const CircleAvatar(
                                          child: Icon(CupertinoIcons.person)),
                                ),
                              ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: MaterialButton(
                      elevation: 1,
                      color: Colors.white,
                      shape: const CircleBorder(),
                      onPressed: (){
                        _showBottomSheet();
                      },child: const Icon(Icons.edit,color: Colors.blue)),
                  )
                ],
              ),
              SizedBox( height: mq.height*.03),
                    
              Text(widget.user.email,style: const TextStyle(color: Colors.black45,fontSize: 16)),
              SizedBox(width: mq.width, height: mq.height*.03),
                    
                    
              TextFormField(
                initialValue: widget.user.name,
                onSaved: (val)=>APIs.me.name=val?? '',
                validator: (val)=>val !=null && val.isNotEmpty?null:'Required Field',
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person,color: Colors.blue,),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'eg Happy Singh', label: const Text('Name')),
                
              ),
              SizedBox( height: mq.height*.02),
              TextFormField(
                initialValue: widget.user.about,
                onSaved: (val)=>APIs.me.about=val?? '',
                validator: (val)=>val !=null && val.isNotEmpty?null:'Required Field',
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.info_outline,color: Colors.blue,),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'eg Feeling Happy', label: const Text('About')),
                
              ),
              SizedBox( height: mq.height*.05),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(shape: const StadiumBorder(),minimumSize: Size(mq.width*.6, mq.height*.06)),
                onPressed: (){
                  if(_formkey.currentState!.validate()){
                    _formkey.currentState!.save();
                    APIs.updateUserInfo().then((value){
                      Dialogs.showSnackbar(context, 'Profile Updated');
                    });
                  }
                },
                icon: const Icon(Icons.edit,size: 28,),
                label: const Text('UPDATE',style: TextStyle(fontSize: 16)),)
                    
              ]),
            ),
          ),
        ),
        
      ),
    );
  }
  void _showBottomSheet(){
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))),
       builder: (_){
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(top: mq.height*.02,bottom: mq.height*.05),
        children: [
           const Text('Pick Profile Picture',textAlign: TextAlign.center,style: TextStyle(fontSize: 20,fontWeight: FontWeight.w400)),

          SizedBox(height: mq.height*.02),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              fixedSize: Size(mq.width*.3, mq.height*.15)),
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              // Pick an image.
              final XFile? image = await picker.pickImage(source: ImageSource.gallery,imageQuality: 80);
              if(image!=null){
                log('Image Path:${image.path}--MimeType:${image.mimeType}');

                setState(() {
                  _image=image.path;
                });

                APIs.updateProfilePicture(File(_image!));

                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
              
            },
             child: Image.asset('images/picture.png')),
             ElevatedButton(
             style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              fixedSize: Size(mq.width*.3, mq.height*.15)),
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              // Pick an image.
              final XFile? image = await picker.pickImage(source: ImageSource.camera,imageQuality: 80);
              if(image!=null){
                log('Image Path:${image.path}');

                setState(() {
                  _image=image.path;
                });
                APIs.updateProfilePicture(File(_image!));
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
            }, child: Image.asset('images/photo.png'))
          ],
          )
        ],
      );
    });
  }
}
