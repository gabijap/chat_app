import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

final FirebaseAuth _fAuth = FirebaseAuth.instance;
final GoogleSignIn _gSignIn = new GoogleSignIn();
var currentUserEmail;

final Firestore _firestore = Firestore.instance;

class UserInfoDetails {
  UserInfoDetails(
      this.providerId, this.displayName, this.email, this.photoUrl, this.uid);

  /// The provider identifier.
  final String providerId;
  /// The provider’s user ID for the user.
  final String uid;
  /// The name of the user.
  final String displayName;
  /// The URL of the user’s profile photo.
  final String photoUrl;
  /// The user’s email address.
  final String email;
}

void signOutGoogle() async {

  await _gSignIn.signOut();
  print("User Sign Out");
}

void main() => runApp(new ChatApp());

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'ChatApp',
      home: new LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  //final FirebaseAuth _fAuth = FirebaseAuth.instance;
  //final GoogleSignIn _gSignIn = new GoogleSignIn();

  Future<FirebaseUser> _SignInWithGoogle() async {

      final GoogleSignInAccount googleUser = await _gSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final FirebaseUser user = await _fAuth.signInWithCredential(credential);
      assert(user.email != null);
      assert(user.displayName != null);
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _fAuth.currentUser();
      assert(user.uid == currentUser.uid);

      currentUserEmail = currentUser.email;

      UserInfoDetails userInfo = new UserInfoDetails(
          user.providerId, user.displayName, user.email, user.photoUrl, user.uid);

      List<UserInfoDetails> providerData = new List<UserInfoDetails>();
      providerData.add(userInfo);

      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => new ChatScreen(userDetails: userInfo),
        ),
      );

      return user;
  }

  /*
  void signOutGoogle() async {

    await _gSignIn.signOut();
    print("User Sign Out");
  }*/

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
          //backgroundColor: Colors.blueGrey,
      body: new Center(
          child: new Container(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Builder(
                  builder: (BuildContext context) {
                    return new Material(
                      borderRadius: new BorderRadius.circular(30.0),
                      child: new Material(
                        elevation: 5.0,
                        child: new MaterialButton(
                          //padding: new EdgeInsets.all(16.0),
                          minWidth: 150.0,
                          onPressed: () => _SignInWithGoogle()
                              .then((FirebaseUser user) => print(user))
                              .catchError((e) => print(e)),
                              child: new Text('Sign in with Google'),
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        );
                      },
                    ),
                    new Builder(
                      builder: (BuildContext context) {
                        return new Material(
                          borderRadius: new BorderRadius.circular(30.0),
                          child: new Material(
                            elevation: 5.0,
                            child: new MaterialButton(
                              minWidth: 150.0,
                              onPressed: () => signOutGoogle(),
                              child: new Text('Sign Out'),
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              )),
        );
  }
}

class ChatScreen extends StatefulWidget {
  final UserInfoDetails userDetails;

  const ChatScreen({Key key, this.userDetails}) : super(key: key);
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();
  String imageUrl = "";
  final ScrollController _scrollController = new ScrollController();
  final reference = FirebaseDatabase.instance.reference().child('messages');
  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Chat App"),
        backgroundColor: (Colors.blue),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              signOutGoogle();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],),
      body: new Column(                                        //modified
        children: <Widget>[                                         //new
          new Flexible(                                             //new
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection("messages")
                  .orderBy('timestamp', descending: true)
                  .limit(12)
                  .snapshots(),
              builder: (context, snapshot) {
                if(!snapshot.hasData) return Container();
                return new ListView.builder(
                    padding: new EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) {
                DocumentSnapshot document =
                snapshot.data.documents[index];

                  return new ChatMessage( //new
                    text: document['text'],
                    imageUrl: document['imageUrl'],//new
                    name: document['name'],
                    photoUrl: document['profilePricUrl'],
                  );
                },
                itemCount: snapshot.data.documents.length,
                );
              },
      ),
          ),
          new Divider(height: 1.0),
          new Container(                                            //new
            decoration: new BoxDecoration(
                color: Theme.of(context).cardColor),                  //new
            child: _buildTextComposer(),                       //modified
          ),                                                        //new
        ],                                                          //new
      ),                                                    //new
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(                                     //modified
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(
                    hintText: "Send a message"),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new Row(
                children: <Widget>[
                  new IconButton(
              icon: new Icon(Icons.crop_original),
                onPressed: () async {
                  print("Picker is called");
                  var image = await ImagePicker.pickImage(source: ImageSource.gallery);
                  File _image = image;
                  print(_image.path);
                  int timestamp = new DateTime.now().millisecondsSinceEpoch;
                  StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child("image_" + timestamp.toString() + ".jpg");
                  StorageUploadTask uploadTask = firebaseStorageRef.putFile(_image);
                  StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
                  var downloadUrl = Uri.parse(await taskSnapshot.ref.getDownloadURL() as String);
                  imageUrl = downloadUrl.toString();
                  _handleSubmitted("");
                  print("Handle submitted" + imageUrl);

                }),
                  new IconButton(
                      icon: new Icon(Icons.send),
                      color: Colors.blue,
                      onPressed: _isComposing
                        ? () => _handleSubmitted(_textController.text) : null
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    setState(() {                                                    //new
      _isComposing = false;                                          //new
    });
    if (_textController.text.length > 0 || imageUrl != "") {
      _firestore.collection('messages').add({
        'name': widget.userDetails.displayName,
        'email': widget.userDetails.email,
        'text' : _textController.text,
        'imageUrl' : imageUrl,
        'profilePricUrl' : widget.userDetails.photoUrl,
        'timestamp' : DateTime.now(),
      });
      imageUrl = "";
      _textController.clear();
    }
  }

}

class ChatMessage extends StatelessWidget {
  final String text;
  final String imageUrl;
  final String name;
  final String photoUrl;
  //UserInfoDetails userDetails;
  ChatMessage({this.text, this.imageUrl, this.name, this.photoUrl});
  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: new CircleAvatar(
              backgroundImage: new NetworkImage(photoUrl),
            ),
          ),
          new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(name, style: Theme.of(context).textTheme.subhead),
                  new Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: text != "" ? new Text(text) : Image.network(imageUrl, height: 100, width: 150)
                  ),
                ],
              )),
        ],
      ),
    );
  }
}


