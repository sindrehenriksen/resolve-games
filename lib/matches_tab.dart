import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  MatchesTabState createState() => MatchesTabState();
}

const List<Widget> games = <Widget>[
  Text('Fussball'),
  Text('Mario Kart'),
];

const List<String> gameIds = <String>[
  'fussball',
  'marioKart',
];

const List<Widget> groups = <Widget>[
  Text('Group A'),
  Text('Group B'),
];

const List<String> groupIds = <String>[
  'groupA',
  'groupB',
];

class MatchesTabState extends State<MatchesTab> {
  final dbRef = FirebaseDatabase.instance.ref();
  // Needed for the first build
  // ignore: avoid_init_to_null
  late DataSnapshot? _data = null;

  final List<bool> _selectedGroup = <bool>[true, false];  // [fussball, marioKart]
  final List<bool> _selectedGame = <bool>[true, false];  // [fussball, marioKart]

  final Map<String, TextEditingController> _matchIdToHomeTeamScoreController = {};
  final Map<String, TextEditingController> _matchIdToAwayTeamScoreController = {};

  double fontSize = 12;

  @override
  void initState() {
    super.initState();
    dbRef.once().then((DatabaseEvent databaseEvent) {
      setState(() {
        _data = databaseEvent.snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_data == null) {
      return const CircularProgressIndicator();
    }

    final group = groupIds[_selectedGroup.indexOf(true)];
    final game = gameIds[_selectedGame.indexOf(true)];
    final teamsData = _data?.child('teams').value as Map<String, dynamic>;
    final matchesData = _data!.child('matches').child(group).child(game).value as Map<String, dynamic>;

    final rows = matchesData.entries.map((entry) {
      final matchId = entry.key;
      _matchIdToHomeTeamScoreController[matchId] = TextEditingController();
      _matchIdToAwayTeamScoreController[matchId] = TextEditingController();
      final homeTeamData = teamsData[entry.value['homeTeam']];
      final awayTeamData = teamsData[entry.value['awayTeam']];
      return DataRow(
        cells: [
          DataCell(Container(
            alignment: Alignment.centerRight,
            child: Tooltip(
              message: homeTeamData['members'].join(', '),
              child: Text(
                homeTeamData['teamName'],
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.right,
              ),
            )
          )),
          DataCell(
            TextField(
              controller: _matchIdToHomeTeamScoreController[matchId],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
              onChanged: (newScore) {
                if (newScore == '') {
                  dbRef.child('matches').child(group).child(game).child(matchId).update({'homeScore': newScore});
                } else {
                  final newScoreInt = int.tryParse(newScore);
                  if (newScoreInt != null && newScoreInt >= 0 && newScoreInt <= 108) {
                    dbRef.child('matches').child(group).child(game).child(matchId).update({'homeScore': '$newScoreInt'});
                  }
                }
              },
            ),
          ),
          DataCell(
            TextField(
              controller: _matchIdToAwayTeamScoreController[matchId],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
              onChanged: (newScore) {
                if (newScore == '') {
                  dbRef.child('matches').child(group).child(game).child(matchId).update({'awayScore': newScore});
                } else {
                  final newScoreInt = int.tryParse(newScore);
                  if (newScoreInt != null && newScoreInt >= 0 && newScoreInt <= 108) {
                    dbRef.child('matches').child(group).child(game).child(matchId).update({'awayScore': '$newScoreInt'});
                  }
                }
              },
            ),
          ),
          DataCell(Tooltip(
            message: awayTeamData['members'].join(', '),
            child: Text(
              awayTeamData['teamName'],
              style: TextStyle(fontSize: fontSize),
            ),
          )),
        ],
      );
    }).toList();

    return Column(
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              direction: Axis.horizontal,
              onPressed: (int index) {
                setState(() {
                  // The button that is tapped is set to true, and the others to false.
                  for (int i = 0; i < _selectedGroup.length; i++) {
                    _selectedGroup[i] = i == index;
                  }
                });
              },
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              constraints: const BoxConstraints(
                minHeight: 40.0,
                minWidth: 80.0,
              ),
              isSelected: _selectedGroup,
              children: groups,
            ),
            const VerticalDivider(),
            ToggleButtons(
              direction: Axis.horizontal,
              onPressed: (int index) {
                setState(() {
                  // The button that is tapped is set to true, and the others to false.
                  for (int i = 0; i < _selectedGame.length; i++) {
                    _selectedGame[i] = i == index;
                  }
                });
              },
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              constraints: const BoxConstraints(
                minHeight: 40.0,
                minWidth: 80.0,
              ),
              isSelected: _selectedGame,
              children: games,
            ),
          ],
        ),

        StreamBuilder<DatabaseEvent>(
          stream: dbRef.onValue.map((event) => event),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _data = (snapshot.data!).snapshot;
            }
            final updatedMatchesData = _data!.child('matches').child(group).child(game).value as Map<String, dynamic>;
            for (final entry in updatedMatchesData.entries) {
              final matchId = entry.key;
              final homeScore = entry.value['homeScore'];
              final awayScore = entry.value['awayScore'];
              _matchIdToHomeTeamScoreController[matchId]?.text = homeScore ?? '';
              _matchIdToHomeTeamScoreController[matchId]?.selection = TextSelection.fromPosition(TextPosition(offset: homeScore?.length ?? 0));
              _matchIdToAwayTeamScoreController[matchId]?.text = awayScore ?? '';
              _matchIdToAwayTeamScoreController[matchId]?.selection = TextSelection.fromPosition(TextPosition(offset: awayScore?.length ?? 0));
            }
            return DataTable(
              columnSpacing: 20,
              headingRowHeight: 10,
              columns: [
                DataColumn(label: Container()),
                DataColumn(label: Container()),
                DataColumn(label: Container()),
                DataColumn(label: Container()),
              ],
              rows: rows,
            );
          }
        ),
      ],
    );
  }
}
