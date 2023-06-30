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
            final group = _groupFilter ? otherGroupId : defaultGroupId;
            final game = _gameFilter ? otherGameId : defaultGameId;
            final teamsData = _data?.child('teams').value as Map<String, dynamic>;
            final matchesData = _data!.child('matches').child(group).child(game).value as Map<String, dynamic>;

            final rows = matchesData.entries.map((entry) {
              final matchId = entry.key;
              final homeTeamData = teamsData[entry.value['homeTeam']];
              final awayTeamData = teamsData[entry.value['awayTeam']];
              final homeScore = entry.value['homeScore'];
              final awayScore = entry.value['awayScore'];
              return DataRow(
                cells: [
                  DataCell(Tooltip(
                    message: homeTeamData['members'].join(', '),
                    child: Text(homeTeamData['teamName'], textAlign: TextAlign.right),
                  )),
                  DataCell(
                    TextField(
                      controller: TextEditingController(text: homeScore),
                      keyboardType: TextInputType.number,
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
                      controller: TextEditingController(text: awayScore),
                      keyboardType: TextInputType.number,
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
                    child: Text(awayTeamData['teamName']),
                  )),
                ],
              );
            }).toList();

            return DataTable(
              headingRowHeight: 10,
              columns: [
                DataColumn(label: Container()),
                DataColumn(label: Container()),
                DataColumn(label: Container()),
                DataColumn(label: Container()),
              ],
              rows: rows,
            );
          },
        ),
      ],
    );
  }
}