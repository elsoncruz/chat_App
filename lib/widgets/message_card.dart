import 'package:chat_as/helper/dialogs.dart';
import 'package:chat_as/helper/my_date_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key,required this.message});
  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe=APIs.user.uid==widget.message.fromId;
    
    return InkWell(
      onLongPress: (){
        _showBottomSheet(isMe);
      },
      child: isMe?_greenMessage():_blueMessage());
          
  }
  Widget _blueMessage(){

    if(widget.message.read.isEmpty){
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type==Type.image?mq.width*.03 : mq.width*.04),
            margin: EdgeInsets.symmetric(horizontal:mq.width*.04,vertical: mq.height*.01),
            decoration: BoxDecoration(color: const Color.fromARGB(255, 180, 204, 223),
            border: Border.all(color: Colors.lightBlue),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30))),
            child:
             widget.message.type==Type.text?
             //show text
             Text(widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),):
             ClipRRect(
          borderRadius: BorderRadius.circular(7),
          //show image
          child: CachedNetworkImage(
            imageUrl: widget.message.msg,
            placeholder: (context,url)=>const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const  Icon(Icons.image,size: 70),
               ),
              ),
             ),
          ),

        Padding(
          padding:  EdgeInsets.only(right: mq.width*.04),
          child: Text(MyDateUtil.getFormattedTime(context: context, time: widget.message.sent),style: const TextStyle(fontSize: 13,color: Colors.black54)),
        ),
      ],
    );
  }
  Widget _greenMessage(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
  
        
        Row(
          children: [
            SizedBox(width: mq.width*.04),
            if(widget.message.read.isNotEmpty)
            const Icon(Icons.done_all_rounded,color: Colors.blue,size: 20),
            const SizedBox(width: 2),
            Text(
              MyDateUtil.getFormattedTime(context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13,color: Colors.black54)),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type==Type.image?mq.width*.03 : mq.width*.03),
            margin: EdgeInsets.symmetric(horizontal:mq.width*.04,vertical: mq.height*.01),
            decoration: BoxDecoration(color: const Color.fromARGB(255, 137, 188, 208),
            border: Border.all(color: Colors.lightBlue),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30))),
            child: 
              widget.message.type==Type.text?            
              Text(widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.black87)): 
              ClipRRect(
          borderRadius: BorderRadius.circular(7),
          //show image
          child: CachedNetworkImage(
            imageUrl: widget.message.msg,
            placeholder: (context,url)=>const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const  Icon(Icons.image,size: 70),
               ),
              ),
          ),
        ),

      ],
    );
  }
   void _showBottomSheet(bool isMe){
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))),
       builder: (_){
      return ListView(
        shrinkWrap: true,
        
        children: [
          Container(
            height: 4,
            margin: EdgeInsets.symmetric(vertical: mq.height*.015, horizontal: mq.width*.4),
            decoration: BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.circular(8))),
           
          
          widget.message.type==Type.text?_OptionItem(icon: const Icon(Icons.copy_all_rounded,color: Colors.blue,size: 26), name: 'Copy Text', onTap:() async {
            await Clipboard.setData(ClipboardData(text:widget.message.msg)).then((value) {
              Navigator.pop(context);
              Dialogs.showSnackbar(context, 'Text Copy');
            });
          }) 
          :_OptionItem(icon: const Icon(Icons.download_rounded,color: Colors.blue,size: 26), name: 'Save Image', onTap:() async {
            Dialogs.showSnackbar(context, 'Not Save Image');
          }),
          if(isMe)
          Divider(
            color: Colors.black54,
            endIndent: mq.width*.04,
            indent: mq.width*.04,
          ),

          if(widget.message.type==Type.text&&isMe)
          _OptionItem(icon: const Icon(Icons.edit,color: Colors.blue,size: 26), name: 'Edit Message', onTap:(){
            Navigator.pop(context);
            _showMessageUpdateDialog();
          }),
          
          if(isMe)
          _OptionItem(icon: const Icon(Icons.delete_forever,color: Colors.red,size: 26), name: 'Delete Message', onTap:() async {
            await APIs.deleteMessage(widget.message).then((value){Navigator.pop(context);});
          }),

          Divider(
            color: Colors.black54,
            endIndent: mq.width*.04,
            indent: mq.width*.04,
          ),

          _OptionItem(icon: const Icon(Icons.remove_red_eye,color: Colors.blue), name: 'Sent At:${MyDateUtil.getFormattedTime(context: context, time: widget.message.sent)}', onTap:(){}),

          _OptionItem(icon: const Icon(Icons.remove_red_eye,color: Colors.green), name: widget.message.read.isEmpty
          ?'Read At:Not seen yet':
           'Read At${MyDateUtil.getFormattedTime(context: context, time: widget.message.read)}', onTap:(){}),

        ],
      );
    });
  }
   void _showMessageUpdateDialog(){ 
  String updateMsg=widget.message.msg;

  showDialog(context: context, builder: (_)=> AlertDialog(
    contentPadding: const EdgeInsets.only(left: 24,right: 24,top: 20,bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Row(children: [Icon(Icons.message,color: Colors.blue,size: 28),Text('Update Message')],),
    content: TextFormField(initialValue: updateMsg,maxLines: null,onChanged: (value)=>updateMsg=value,decoration:InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
    actions: [
      MaterialButton(onPressed: (){
        Navigator.pop(context);
      },child: const Text('Cancel',style: TextStyle(color: Colors.blue,fontSize: 16))),

      MaterialButton(onPressed: (){
        Navigator.pop(context);
        APIs.updateMessage(widget.message, updateMsg);
      },child: const Text('Update',style: TextStyle(color: Colors.blue,fontSize: 16)))
    ],
  ));
 }
}
class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        letterSpacing: 0.5)))
          ]),
        ));
  }
 
}
