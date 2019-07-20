import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String _name = "Name";

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

final Firestore _firestore = Firestore.instance;

/*  Use the google sign in data to authenticate a
    FirebaseUser and then return that user.
 */
Future<String> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
  );

  final FirebaseUser user = await _auth.signInWithCredential(credential);

  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  return 'signInWithGoogle succeeded: $user';
}

/*  Sign out of the current Google account.*/
void signOutGoogle() async{
  await googleSignIn.signOut();
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
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: Text('Chat App'),
          centerTitle: true,
          backgroundColor: Colors.lime,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GoogleSignInButton(
                onPressed: () {
                  signInWithGoogle().whenComplete(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) {
                            return ChatScreen();
                          },
                      ),
                    );
                  });
                },
              )
            ],
          ),
        )
    );
  }
}

class ChatScreen extends StatefulWidget {
  static const String id = "CHAT";
  final FirebaseUser user;

  const ChatScreen({Key key, this.user}) : super(key: key);
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Chat App"),
      backgroundColor: (Colors.lime),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            signOutGoogle();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],),
      body: new Column(                                        //modified
        children: <Widget>[                                         //new
          new Flexible(                                             //new
            child: new ListView.builder(                            //new
              padding: new EdgeInsets.all(8.0),                     //new
              reverse: true,                                        //new
              itemBuilder: (_, int index) => _messages[index],      //new
              itemCount: _messages.length,                          //new
            ),                                                      //new
          ),
          new Divider(height: 1.0),                                 //new
          new Container(                                            //new
            decoration: new BoxDecoration(
                color: Theme.of(context).cardColor),                  //new
            child: _buildTextComposer(),                       //modified
          ),                                                        //new
        ],                                                          //new
      ),                                                            //new
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
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(
                    hintText: "Send a message"),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                  icon: new Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (_textController.text.length > 0) {
      _firestore.collection('messages').add({
        //'name':
        'text' : _textController.text,
        //'profilePricUrl' :
        'timestamp' : DateTime.now(),
      });
      _textController.clear();
      ChatMessage message = new ChatMessage( //new
        text: text, //new
      ); //new
      setState(() { //new
        _messages.insert(0, message); //new
      });
    }
  }

}

class ChatMessage extends StatelessWidget {
  ChatMessage({this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: new CircleAvatar(child: new Text(_name[0])),
          ),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(_name, style: Theme.of(context).textTheme.subhead),
              new Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: new Text(text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*class ChatScreen extends StatefulWidget {
  static const String id = "CHAT";
  final FirebaseUser user;

  const ChatScreen({Key key, this.user}) : super(key: key);
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = new TextEditingController();
  final ScrollController _scrollController = new ScrollController();

  Future<void> callback() async{
    if(_textController.text.length > 0) {
      await
      _firestore.collection('messages').add({
        'text' : _textController.text,
        'from' : widget.user.email,
      });
      _textController.clear();
      _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          curve:  Curves.easeOut,
      duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text("Chat App"),
          backgroundColor: (Colors.lime),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                signOutGoogle();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            )
          ],
      ),
      body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('messages').snapshots(),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData)
                      return Center(
                        child: CircularProgressIndicator(),
                      );

                    List<DocumentSnapshot> docs = snapshot.data.documents;

                    List<Widget> messages = docs
                        .map((doc) => Message(
                            from: doc.data['from'],
                            text: doc.data['text'],
                            //me: widget.user.email = doc.data['from']
                    ))
                    .toList();
                    return ListView(
                      controller: _scrollController,
                      children: <Widget>[
                        ...messages,
                      ],
                    );
                  },
                ),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onSubmitted: (value) => callback(),
                        decoration: InputDecoration(
                          hintText: "Enter your message...",
                          border: const OutlineInputBorder(),
                        ),
                        controller: _textController,
                      ),
                    ),
                    SendButton(
                      text: "Send",
                      callback: callback,
                    )
                  ],
                ),
              )
            ],
          ),
      ),
    );
  }
}

class SendButton extends StatelessWidget{
  final String text;
  final VoidCallback callback;

  const SendButton({Key key, this.text, this.callback}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      color: Colors.lime,
      onPressed: callback,
      child: Text(text),
    );
  }
}

class Message extends StatelessWidget{
  final String from;
  final String text;

  final bool me;

  const Message({Key key, this.from, this.text, this.me}) : super(key : key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            from,
          ),
          Material(
            color: me ? Colors.teal : Colors.red,
            borderRadius: BorderRadius.circular(10.0),
            elevation: 6.0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              child: Text(
                text,
              ),
            ),
          )
        ],
      ),
    );
  }
}*/

