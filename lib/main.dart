import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:resolve_games/init_matches.dart';
import 'package:resolve_games/init_teams.dart';
import 'package:resolve_games/matches_table.dart';
import 'package:resolve_games/teams_table.dart';

import 'firebase_options.dart';
import 'game_table.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Add initial team and match data to database
  WidgetsFlutterBinding.ensureInitialized();
  addInitialTeamData();
  addInitialMatchesData();

  // Run the app
  runApp(const ResolveGamesApp());
}

class ResolveGamesApp extends StatelessWidget {
  const ResolveGamesApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resolve Summer Games 2023',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(0, 122, 202, 1)),
        useMaterial3: true,
      ),
      home: const ResolveGamesHomePage(title: 'Resolve Summer Games 2023'),
    );
  }
}

class ResolveGamesHomePage extends StatefulWidget {
  const ResolveGamesHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<ResolveGamesHomePage> createState() => _ResolveGamesHomePageState();
}

class _ResolveGamesHomePageState extends State<ResolveGamesHomePage> {

  final List<Tab> tabs = const [
    Tab(text: 'Teams'),
    Tab(text: 'Table'),
    Tab(text: 'Matches'),
    Tab(text: 'Rules'),
  ];

  String rulesMarkdownContent = '';

  @override
  void initState() {
    super.initState();
    loadRulesMarkdown();
  }

  Future<void> loadRulesMarkdown() async {
    String content = await rootBundle.loadString('assets/rules.md');
    setState(() {
      rulesMarkdownContent = content;
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
    return DefaultTabController(
      length: tabs.length,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the HomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: Center(child: SizedBox(width: 700, child: TabBarView(
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          children: [
            const Align(alignment: Alignment.topCenter, child: TeamsTable()),
            const Align(alignment: Alignment.topCenter, child: GameTable()),
            const Align(alignment: Alignment.topCenter, child: MatchesTable()),
            Align(alignment: Alignment.topCenter, child: Markdown(data: rulesMarkdownContent)),
          ],
        ))),
      ),
    );
  }
}
