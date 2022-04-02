import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_isolate/provider/user_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  var userProvider = UserProvider();

  @override
  void initState() {
    super.initState();

    userProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    userProvider.loadUserWithIsolate();
                  },
                  child: const Text('ISOLATE'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    userProvider.loadUserWithOutIsolate();
                  },
                  child: const Text('NON ISOLATE'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ChangeNotifierProvider.value(
              value: userProvider,
              child: Consumer<UserProvider>(
                builder: (context, provider, child) => provider.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(provider.consumedTime),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: provider.users.length,
                              itemBuilder: (context, index) {
                                var user = provider.users[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 36,
                                    backgroundImage: NetworkImage(user.picture),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  title: Text(user.fullName),
                                  subtitle: Text(user.email),
                                );
                              },
                            ),
                          )
                        ],
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
