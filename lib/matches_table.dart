import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MatchesTable extends StatefulWidget {
  const MatchesTable({super.key});

  @override
  MatchesTableState createState() => MatchesTableState();
}

class MatchesTableState extends State<MatchesTable> {
  final matchesRef = FirebaseDatabase.instance.ref().child('matches');
  late Map<String, dynamic> _matchesData;
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
    _matchesData = <String, dynamic>{};
    matchesRef.once().then((DatabaseEvent databaseEvent) {
      setState(() {
        _matchesData = databaseEvent.snapshot.child(defaultGroupId).child(defaultGameId).value as Map<String, dynamic>;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
          stream: matchesRef.onValue.map((event) => event),
          builder: (context, snapshot) {
            final group = _groupFilter ? otherGroupId : defaultGroupId;
            final game = _gameFilter ? otherGameId : defaultGameId;
            if (snapshot.hasData) {
              _matchesData = (snapshot.data!).snapshot.child(group).child(game).value as Map<String, dynamic>;
            }

            final rows = _matchesData.entries.map((entry) {
              final matchId = entry.key;
              final homeTeam = entry.value['homeTeam'];
              final awayTeam = entry.value['awayTeam'];
              final homeScore = entry.value['homeScore'];
              final awayScore = entry.value['awayScore'];
              return DataRow(
                cells: [
                  DataCell(Text(homeTeam)),
                  DataCell(Text(awayTeam)),
                  DataCell(
                    TextField(
                      controller: TextEditingController(text: homeScore),
                      keyboardType: TextInputType.number,
                      onSubmitted: (newScore) {
                        if (newScore == '') {
                          matchesRef.child(group).child(game).child(matchId).update({'homeScore': newScore});
                        } else {
                          final newScoreInt = int.tryParse(newScore);
                          if (newScoreInt != null && newScoreInt >= 0 && newScoreInt <= 108) {
                            matchesRef.child(group).child(game).child(matchId).update({'homeScore': '$newScoreInt'});
                          }
                        }
                      },
                    ),
                  ),
                  DataCell(
                    TextField(
                      controller: TextEditingController(text: awayScore),
                      keyboardType: TextInputType.number,
                      onSubmitted: (newScore) {
                        if (newScore == '') {
                          matchesRef.child(group).child(game).child(matchId).update({'awayScore': newScore});
                        } else {
                          final newScoreInt = int.tryParse(newScore);
                          if (newScoreInt != null && newScoreInt >= 0 && newScoreInt <= 108) {
                            matchesRef.child(group).child(game).child(matchId).update({'awayScore': '$newScoreInt'});
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            }).toList();

            return DataTable(
              columns: const [
                DataColumn(label: Text('Home Team')),
                DataColumn(label: Text('Away Team')),
                DataColumn(label: Text('Home Score')),
                DataColumn(label: Text('Away Score')),
              ],
              rows: rows,
            );
          },
        ),
      ],
    );
  }
}