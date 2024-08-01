// ignore_for_file: deprecated_member_use

import 'package:chat_as/api/apis.dart';
import 'package:chat_as/helper/dialogs.dart';
import 'package:chat_as/main.dart';
import 'package:chat_as/models/chat_user.dart';
import 'package:chat_as/screen/profile_screen.dart';
import 'package:chat_as/widgets/chatuser_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => MyWidgetState();
}

class MyWidgetState extends State<HomeScreen> {
  List<ChatUser>_list=[];
  final List<ChatUser>_searchlist=[];  
  bool _isSearching=false;


@override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
    
    SystemChannels.lifecycle.setMessageHandler((message){
      if(APIs.auth.currentUser!=null){
           if(message.toString().contains('resume')){ APIs.updateActiveStatus(true);}
      if(message.toString().contains('pause')){ APIs.updateActiveStatus(false);}
      }
      return Future.value(message);
    });
  }


  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      onTap: ()=>FocusScope.of(context).unfocus(),
      
      child: WillPopScope(
        onWillPop: () {
          if(_isSearching){
            setState(() {
              _isSearching=!_isSearching;

            });
          return Future.value(false);
          }else{
            return Future.value(true);
          }
        },
          
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            title: _isSearching? 
             TextField(
              decoration: const InputDecoration(border: InputBorder.none,hintText: 'Name,email,...'),
              autofocus: true,
              style: const TextStyle(fontSize: 17,letterSpacing: 0.5),
              onChanged:(val){
              _searchlist.clear();
              
                for (var i in _list){
                  if(i.name.toLowerCase().contains(val.toLowerCase())||
                  i.email.toLowerCase().contains(val.toLowerCase())){
                    _searchlist.add(i);
                  }
                  setState(() {
                    _searchlist;
                  });
                }
              },
            ): const Text('Smart Browser'),
            actions: [
              IconButton(onPressed:(){
                setState(() {
                  _isSearching=!_isSearching;
                });
              }, icon: Icon(_isSearching? 
                  CupertinoIcons.clear_circled_solid
                  
                  
                  :Icons.search)),
              IconButton(onPressed:(){
                Navigator.push(context, MaterialPageRoute(builder: (_)=> ProfileScreen(user: APIs.me)));
              }, icon: const Icon(Icons.more_vert)),
            ],
        
        
            ),
            backgroundColor: const Color.fromARGB(255, 213, 226, 238),
        
            floatingActionButton: 
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(255, 81, 200, 255),
                onPressed: () {
                _addChatUserDialog();
              },
              child: const Icon(Icons.add_comment_outlined,color: Colors.white)),
            ),
          //body
          body: StreamBuilder(
            stream: APIs.getMyUserId(),
            builder: (context,snapshot){
            switch(snapshot.connectionState){
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
        
                case ConnectionState.active:
                case ConnectionState.done: 
             return StreamBuilder(
            stream: APIs.getAllUser(snapshot.data?.docs.map((e) => e.id).toList()??[]),
            builder: (context, snapshot) {
              switch(snapshot.connectionState){
                case ConnectionState.waiting:
                case ConnectionState.none:
                 // return const Center(child: CircularProgressIndicator());
        
                case ConnectionState.active:
                case ConnectionState.done:  
        
                
                final data=snapshot.data?.docs;
                _list=data?.map((e) => ChatUser.fromJson(e.data())).toList()??[];
                  if (_list.isNotEmpty) {
                            return ListView.builder(
                                itemCount: _isSearching
                                    ? _searchlist.length
                                    : _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ChatUserCard(
                                      user: _isSearching
                                          ? _searchlist[index]
                                          : _list[index]);
                                });
                    } else {
                            return const Center(
                              child: Text('No Connections Found!',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
              }  
            } 
          );
          }  
          },
          ), 
        ),
      ),
    );
  }
// for adding new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text('  Add User')
                ],
              ),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: 'Email Id',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.blue, fontSize: 16))),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await APIs.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User does not Exists!');
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}