import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chat_as/models/chat_user.dart';
import 'package:chat_as/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

class APIs{
  static FirebaseAuth auth = FirebaseAuth.instance;

  static FirebaseStorage storage = FirebaseStorage.instance;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static FirebaseMessaging  fMessaging = FirebaseMessaging.instance;

  static Future<void>getFirebaseMessagingToken() async{
     await fMessaging.requestPermission();

     fMessaging.getAPNSToken().then((t) {
        if(t!=null){
          me.pushToken=t;
          log('Push Token:$t');
        }
     });

  }

  static ChatUser me = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I'm using Smart Browser!",
      image: user.photoURL.toString(),
      createdAt: '',
      isOnline: false,
      lastActive: '',
      pushToken: '');

  static User get user=>auth.currentUser!;

  static Future<bool>userExists()async{
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<bool>addChatUser(String email)async{
    final data =await firestore.collection('users').where('email',isEqualTo: email).get();

    if(data.docs.isNotEmpty&&data.docs.first.id!=user.uid){
      firestore.collection('users').doc(user.uid).collection('my_users').doc(data.docs.first.id).set({});
      return true;
    }
    else{
      return false;
    }
  }

  static Future<void>getSelfInfo()async{
     await firestore.collection('users').doc(user.uid).get().then((user) async {
        if(user.exists){
          me=ChatUser.fromJson(user.data()!);
          await getFirebaseMessagingToken();
          APIs.updateActiveStatus(true);
          log('My Data:${user.data()}');
        }else{
         await createUser().then((value) => getSelfInfo());
        }
     });
  }


  static Future<void>createUser()async{
    final time=DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser=ChatUser(id: user.uid,
          name: user.displayName.toString(),
          email: user.email.toString(),
          about: "Hey i'm using SmartBrowser!",
          image: user.photoURL.toString(),
          createdAt: time,
          isOnline: false,
          lastActive: time,
          pushToken: ''
          );
    return await firestore
    .collection('users')
    .doc(user.uid)
    .set(chatUser.toJson());

}
static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUser(List<String> userIds){
  return firestore.collection('users')
  .where('id',whereIn: userIds.isEmpty?['']:userIds)
  //.where('id',isNotEqualTo: user.uid)
  .snapshots();
}

static Future<void>sendFirstMessage(ChatUser chatUser,String msg, Type type)async{
    await firestore.collection('users').doc(chatUser.id).collection('my_users').doc(user.uid).set({}).then((value) => sendMessage(chatUser, msg, type));
  }

static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUserId(){
  return firestore
  .collection('users')
  .doc(user.uid)
  .collection('my_users')
  .snapshots();
}
static Future<void>updateUserInfo()async{
    await firestore.collection('users').doc(user.uid).update({'name':me.name,'about':me.about});
  }
  static Future<void>updateProfilePicture(File file)async{
    final ext=file.path.split('.').last;
    final ref=storage.ref().child('profilePicture/${user.uid}.$ext');
    await ref.putFile(file,SettableMetadata(contentType: 'image/$ext')).then((p0){
      log('Data Transferred:${p0.bytesTransferred/1000}kb');
    });
    me.image=await ref.getDownloadURL();
    await firestore
    .collection('users')
    .doc(user.uid)
    .update({'image':me.image});
  }

  static getConversationID(String id)=>user.uid.hashCode<=id.hashCode
        ? '${user.uid}_$id'
        :'${id}_${user.uid}';

  //chat screen related apis
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    ChatUser user){
  return firestore
  .collection('chats/${getConversationID(user.id)}/messages/')
  .orderBy('sent',descending: true)
  .snapshots();
}

//chat collection

static Future<void>sendMessage(ChatUser chatUser,String msg, Type type)async{

  final time=DateTime.now().microsecondsSinceEpoch.toString();

  final Message message=Message(
    toId: chatUser.id,
    msg: msg,
    read: '', 
    type: type, 
    fromId: user.uid, 
    sent: time);

  final ref=firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
await ref.doc(time).set(message.toJson()).then((value) => sendPushNotification(chatUser,type==Type.text? msg: 'image'));
}

static Future<void>updateMessageReadStatus(Message message)async{
  firestore.collection('chats/${getConversationID(message.fromId)}/messages/').doc(message.sent).update({'read':DateTime.now().millisecondsSinceEpoch.toString()});
}

static Stream<QuerySnapshot<Map<String,dynamic>>>getLastMessage(
  ChatUser user){
    return firestore
      .collection('chats/${getConversationID(user.id)}/messages/')
      .orderBy('sent',descending: true)
      .limit(1)
      .snapshots();
  }

  static Future<void>sendChatImage(ChatUser chatUser,File file) async {

    final ext=file.path.split('.').last;
    final ref=storage.ref().child('images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(file,SettableMetadata(contentType: 'image/$ext')).then((p0){
      log('Data Transferred:${p0.bytesTransferred/1000}kb');
    });
    final imageUrl=await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);

  }
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(ChatUser chatUser){
  return firestore.collection('users').where('id',isEqualTo: chatUser.id).snapshots();
}  
  static Future<void> updateActiveStatus(bool isOnline)async{
     firestore
      .collection('users')
      .doc(user.uid).update({
        'is_online':isOnline,
        'last_active':DateTime.now().millisecondsSinceEpoch.toString(),
        'push_token':me.pushToken});
  }
   static Future<void>sendPushNotification(ChatUser chatUser,String msg) async{

    try{
      final body= {
      "to":chatUser.pushToken,
      "notification":{
        "title":me.name,
        "body":msg,
        "android_channel_id": "chats"
      },
    };
   
    var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
    headers: {
      HttpHeaders.contentTypeHeader:'application/json',
      HttpHeaders.authorizationHeader:'key=AAAArFYamvQ:APA91bEM3_t8D3Y-wxNXYIDTkvehKPSzk5nQXn3UCGwGNPzt7PWbUnm0b33N24zsR6slHYnVKFZGuPEiVDZs70BXEh_2vM-NcPi4aQsaHgo1GFgzLJlk8EtrjXQtCzhkO7WKozsrpECB'
    },
    body: jsonEncode(body));
    log('Response status: ${res.statusCode}');
    log('Response body: ${res.body}');
    }
    catch(e){
      log('\nsendPushNotificationE: $e');
    }
   }
   
    //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
