import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

// 更新可能なデータ(Providerを使って状態管理を行う)
class UserState extends ChangeNotifier {
  User? user;

  void setUser(User newUser) {
    user = newUser;
    // このオブジェクトに登録されているすべてのリスナーに通知される
    notifyListeners();
  }
}

Future<void> main() async {
  // Flutterアプリケーションが実行される前にウィジェットバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebaseの初期化に失敗しました: $e");
  }

  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  // ユーザーの情報を管理するデータ
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserState>(
      create: (context) => UserState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // アプリ名
        title: 'ChatApp',
        theme: ThemeData(
          // テーマカラー
          primarySwatch: Colors.blue,
        ),
        // ログイン画面を表示
        home: LoginPage(),
      ),
    );
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 入力されたメールアドレス
  String newUserEmail = "";
  // 入力されたパスワード
  String newUserPassword = "";

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              // テキスト入力のラベルを設定
              decoration: InputDecoration(labelText: "メールアドレス"),
              onChanged: (String value) {
                setState(() {
                  newUserEmail = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
                decoration: InputDecoration(labelText: "パスワード"),
                // パスワードが見えないようにする
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    newUserPassword = value;
                  });
                }),
            const SizedBox(height: 15),
            ElevatedButton(
                child: Text('ユーザー登録'),
                onPressed: () async {
                  try {
                    // メール/パスワードでユーザー登録
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final result = await auth.createUserWithEmailAndPassword(
                        email: newUserEmail, password: newUserPassword);
                    // ユーザー情報を更新
                    userState.setUser(result.user!);

                    // 少し遅延を挟む
                    await Future.delayed(Duration(milliseconds: 1000));
                    // チャット画面に推移
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {
                        // !はnullでないことを示している
                        return ChatPage();
                      }),
                    );
                  } catch (e) {
                    // Text('ユーザー登録に失敗しました: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ユーザー登録に失敗しました: $e')),
                    );
                  }
                }),
            const SizedBox(height: 10),
            OutlinedButton(
              child: Text('ログイン'),
              onPressed: () async {
                try {
                  // メール/パスワードでログイン
                  final FirebaseAuth auth = FirebaseAuth.instance;
                  final result = await auth.signInWithEmailAndPassword(
                    email: newUserEmail,
                    password: newUserPassword,
                  );
                  // ユーザー情報を更新
                  userState.setUser(result.user!);
                  // チャット画面に推移
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      // !はnullでないことを示している
                      return ChatPage();
                    }),
                  );
                } catch (e) {
                  // ログインに失敗した場合
                  Text('ログインに失敗しました');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// チャット画面用Widget
class ChatPage extends StatelessWidget {
  ChatPage();

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                // ログアウト処理
                await FirebaseAuth.instance.signOut();
                // ログイン画面に推移 + チャット画面を破棄
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) {
                    return LoginPage();
                  }),
                );
              }),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Text('ログイン情報:${user.email}'),
          ),
          // 親ウィジェット内で子ウィジェットが可能な限りのスペースを占めることを可能にする
          Expanded(
            // Streambuilder
            // 非同期処理の結果を元にWidgetを作れる
            child: StreamBuilder<QuerySnapshot>(
                // 投稿メッセージ一覧を取得
                // 投稿日時でソート
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  // データが取得できた場合
                  if (snapshot.hasData) {
                    final List<DocumentSnapshot> documents =
                        snapshot.data!.docs;
                    // 取得した投稿メッセージ一覧を元にリスト表示
                    return ListView(
                      children: documents.map((document) {
                        return Card(
                          child: ListTile(
                            title: Text(document['text']),
                            subtitle: Text(document['email']),
                            // 自分の投稿メッセージの場合は削除ボタンを表示
                            trailing: document['email'] == user.email
                                ? IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      // 投稿メッセージのドキュメントを削除
                                      await FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(document.id)
                                          .delete();
                                    },
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  }
                  // データが読込中の場合
                  return Center(
                    child: Text('読込中...'),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            // 投稿画面に遷移
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                // 引数からユーザー情報を渡す
                return AddPostPage(user);
              }),
            );
          }),
    );
  }
}

// 投稿画面用Widget
class AddPostPage extends StatefulWidget {
  // 引数からユーザー情報を受け取る
  AddPostPage(this.user);
  // ユーザー情報
  final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  // 入力した投稿メッセージ
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 投稿メッセージ入力
              TextFormField(
                  decoration: InputDecoration(labelText: '投稿メッセージ'),
                  // 複数行のテキスト入力
                  keyboardType: TextInputType.multiline,
                  // 最大3行
                  maxLines: 3,
                  onChanged: (String value) {
                    setState(() {
                      messageText = value;
                    });
                  }),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('投稿'),
                  onPressed: () async {
                    final date =
                        DateTime.now().toLocal().toIso8601String(); // 現在の日時
                    final email = widget.user.email; // AddPostPageのデータを参照
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('posts') // コレクションID指定
                        .doc() // ドキュメントID指定
                        .set({
                      'text': messageText,
                      'email': email,
                      'date': date,
                    });
                    // チャット画面に戻る
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
