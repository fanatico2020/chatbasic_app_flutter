
import 'dart:io';
import 'package:chatbasic/chat_message.dart';
import 'package:chatbasic/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? _currentUser;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState((){
        _currentUser = user;
      });

    });
  }

  _getUser() async{
    if(_currentUser != null) return _currentUser;
    try{
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount!.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;
      return user;
    }catch(error){
      return null;
    }
  }

  void _sendMessage({String? text,File? img}) async{

    final User user = await _getUser();

    if(user == null){
      _scaffoldKey.currentState!.showSnackBar(
        SnackBar(
          content: Text('Não foi possível fazer o login. tente novamente!'),
          backgroundColor: Colors.red,
        )
      );
    }

    final metadata = SettableMetadata(contentType: "image/jpeg");
    Map<String,dynamic>data = {
      'uid':user.uid,
      'senderName':user.displayName,
      'senderPhotoUrl':user.photoURL,
      'time':Timestamp.now(),
    };

    if(img != null) {
      UploadTask uploadTask  = FirebaseStorage.instance.ref().child(
         DateTime.now().millisecondsSinceEpoch.toString()
      ).putFile(img,metadata);

      setState((){
        _isLoading = true;
      });
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot)async {

        switch(taskSnapshot.state){
          case TaskState.running:
            final progress = 100.0 * (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            print('Upload is $progress% complete.');
            break;
          case TaskState.paused:
            print('Upload is paused.');
            break;
          case TaskState.canceled:
            print('Upload was canceled');
            break;
          case TaskState.error:
            break;
          case TaskState.success:

            data['imgUrl'] = await taskSnapshot.ref.getDownloadURL();
            print(data['imgUrl']);

        }
      });
      setState((){
        _isLoading = false;
      });
    }
    if(text != null)data['text'] = text;

    FirebaseFirestore.instance.collection('messages').add(data);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _currentUser != null ? 'Olá, ${_currentUser?.displayName}':'Chat App'
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          _currentUser != null ? IconButton(onPressed: (){
            FirebaseAuth.instance.signOut();
            googleSignIn.signOut();
            _scaffoldKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text('Você saiu com sucesso!'),

                )
            );
          }, icon: Icon(Icons.exit_to_app)) : Container()
        ],
      ),
      body:Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('time').snapshots(),
              builder: (context,snapshot){
                switch(snapshot.connectionState){
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents = snapshot.data!.docs.reversed.toList();
                    return ListView.builder(
                      itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context,index){
                        return ChatMessage(documents[index].data() as Map<String,dynamic>,true);
                        }
                    );
                }
              },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
