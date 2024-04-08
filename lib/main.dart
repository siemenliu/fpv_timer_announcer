import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fpv_timer_announcer/tts.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TTSTool();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Lap {
  final int id;
  final int duration;
  final int rssi;
  final int absTime;

  const Lap({
    required this.id,
    required this.duration,
    required this.rssi,
    required this.absTime,
  });
}

class Player {
  final String name;
  final String ipaddr;
  final List<Lap> laps;

  const Player({
    required this.name,
    required this.ipaddr,
    required this.laps,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    List<Lap> lapList = [];
    for (Map<String, dynamic> l in json['laps']) {
      Lap lap = Lap(
        id: l['id'],
        duration: l['duration'],
        rssi: l['rssi'],
        absTime: l['abs_time'],
      );
      lapList.add(lap);
      // TTSTool().speak("${json['name']}玩家 ${lap.duration / 1000}秒");
    }

    return switch (json) {
      {
        'name': String name,
        'ipaddr': String ipaddr,
      } =>
        Player(
          name: name,
          ipaddr: ipaddr,
          laps: lapList,
        ),
      _ => throw const FormatException('Failed to load player.'),
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Player>> playerList = fetchPlayer();
  final Map<String, int> playerMap = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        playerList = fetchPlayer();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void speakByPlayer(Player player) {
    String content =
        "玩家：${player.name} 用时：${player.laps.last.duration / 1000}秒";
    TTSTool().speak(content);
  }

  Future<List<Player>> fetchPlayer() async {
    final List<Player> players = [];
    final response =
        await http.get(Uri.parse('http://192.168.1.168:8000/mock.json'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      List ps = body['status']['players'];
      debugPrint('ps count: ${ps.length}');
      for (int i = 0; i < ps.length; i++) {
        Player p = Player.fromJson(ps[i]);
        players.add(p);

        bool ttsSpeak = false;
        if (!playerMap.containsKey(p.name)) {
          playerMap[p.name] = p.laps.length;
          ttsSpeak = true;
        } else {
          if (playerMap[p.name] != p.laps.length) {
            playerMap[p.name] = p.laps.length;
            ttsSpeak = true;
          }
        }
        if (ttsSpeak) speakByPlayer(p);
      }
      return players;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load player');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FPV Timer Announcer"),
      ),
      body: FutureBuilder(
        future: playerList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              List<Player> playerList = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: playerList.length,
                itemBuilder: (BuildContext context, int index) {
                  Player player = playerList[index];
                  debugPrint(
                      "player ${player.name}, laps-${player.laps.length}");
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: player.laps.length,
                        itemBuilder: (BuildContext context, int index) {
                          Lap lap = player.laps[index];
                          return ListTile(
                            leading: const Icon(Icons.timer),
                            trailing: const Text(
                              "Best",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 12),
                            ),
                            title: Text(
                              "${lap.duration / 1000.0}s",
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 15),
                            ),
                            subtitle: Text(
                              "RSSI: ${lap.rssi}",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              return const Center(child: Text("Empty"));
            }
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
