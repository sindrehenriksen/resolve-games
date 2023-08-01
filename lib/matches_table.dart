import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MatchesTable extends StatefulWidget {
  const MatchesTable({super.key});

  @override
  MatchesTableState createState() => MatchesTableState();
}

class MatchesTableState extends State<MatchesTable> {
  final dbRef = FirebaseDatabase.instance.ref();
  // Needed for the first build
  // ignore: avoid_init_to_null
  late DataSnapshot? _data = null;

  bool _groupFilter = false;
  final defaultGroupId = 'groupA';
  final defaultGroupName = 'Group A';
  final otherGroupId = 'groupB';
  final otherGroupName = 'Group B';

  bool _gameFilter = false;
  final defaultGameId = 'fussball';
  final defaultGameName = 'Fussball';
  final otherGameId = 'marioKart';
  final otherGameName = 'Mario Kart';

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

    final group = _groupFilter ? otherGroupId : defaultGroupId;
    final game = _gameFilter ? otherGameId : defaultGameId;
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
            Text(defaultGroupName),
            Switch(
              value: _groupFilter,
              onChanged: (value) {
                setState(() {
                  _groupFilter = value;
                });
              },
            ),
            Text(otherGroupName),
            const VerticalDivider(),
            Text(defaultGameName),
            Switch(
              value: _gameFilter,
              onChanged: (value) {
                setState(() {
                  _gameFilter = value;
                });
              },
            ),
            Text(otherGameName),
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
