import 'dart:isolate';
import 'dart:convert' as convert;
import 'package:easy_isolate/easy_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<User> _mapToUsers(Map<String, dynamic> json) {
  if (kDebugMode) print('JSON: $json');

  var results = (json['results'] ?? []) as List<dynamic>;
  return results.map((e) => User.fromJson(e)).toList();
}

class UserProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final _users = <User>[];
  List<User> get users => _users;

  late String _consumedTime = '';
  String get consumedTime => _consumedTime;

  late var _startedTime = DateTime.now().millisecondsSinceEpoch;
  late var _endedTime = DateTime.now().millisecondsSinceEpoch;

  var _counterCalls = 0;
  final _maxCalls = 5;
  final _usersLengthPerCall = 200;

  final _worker = Worker();

  Future<void> init() async {
    await _worker.init(
      _mainMessageHandlelr,
      _isolateMessageHandler,
      errorHandler: kDebugMode ? print : null,
      queueMode: true,
    );
  }

  void _showLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void _hideLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUserWithIsolate() async {
    _counterCalls = 0;
    _startedTime = DateTime.now().millisecondsSinceEpoch;
    _showLoading();

    // as Queue process
    _loadUserWithIsolateOne();
    // Parallel requests
    // _loadUserWithIsolateTwo();
  }

  void _calculateConsumedTime() {
    _endedTime = DateTime.now().millisecondsSinceEpoch;
    var diffTime = (_endedTime - _startedTime) / 1000;
    _consumedTime = '$diffTime seconds';
  }

  void _loadUserWithIsolateOne() {
    for (var i = 1; i <= _maxCalls; i++) {
      _worker.sendMessage(
        'https://randomuser.me/api/?results=$_usersLengthPerCall&page=$i',
      );
    }
  }

  // Please be aware on this calls, because it makes high latency
  Future<void> _loadUserWithIsolateTwo() async {
    final results = await Parallel.map(
      List.generate(
        _maxCalls,
        (i) =>
            'https://randomuser.me/api/?results=$_usersLengthPerCall&page=${i + 1}',
      ),
      _fetchUser,
    );

    for (var result in results) {
      _users.addAll(result);
    }

    _calculateConsumedTime();
    _hideLoading();
  }

  Future<void> loadUserWithOutIsolate() async {
    _users.clear();
    _startedTime = DateTime.now().millisecondsSinceEpoch;
    _showLoading();

    for (var i = 1; i <= _maxCalls; i++) {
      var users = await _fetchUser(
        'https://randomuser.me/api/?results=$_usersLengthPerCall&page=$i',
      );

      _users.addAll(users);
    }

    _calculateConsumedTime();
    _hideLoading();
  }

  void close() {
    _worker.dispose(immediate: true);
  }

  // PARALLEL

  static Future<List<User>> _fetchUser(String url) async {
    var uri = Uri.parse(url);
    var response = await http.get(uri);
    return _mapToUsers(convert.jsonDecode(response.body));
  }

  // WORKER

  void _mainMessageHandlelr(dynamic data, SendPort isolateSendPort) {
    if (data is List<User>) {
      _counterCalls++;
      _users.addAll(data);

      if (_maxCalls <= _counterCalls) {
        _calculateConsumedTime();
        _hideLoading();
      }
    }
  }

  static void _isolateMessageHandler(
    dynamic data,
    SendPort mainSendPort,
    SendErrorFunction sendError,
  ) async {
    if (data is String) {
      var response = await http.get(Uri.parse(data));
      var result = convert.jsonDecode(response.body);
      var users = _mapToUsers(result);
      mainSendPort.send(users);
    }
  }
}

class User {
  late final String fullName, picture, email;

  User({
    required this.fullName,
    required this.picture,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName:
          "${json['name']['title']}. ${json['name']['first']} ${json['name']['last']}",
      picture: json['picture']['large'],
      email: json['email'],
    );
  }
}
