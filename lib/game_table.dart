import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class GameTable extends StatefulWidget {
  const GameTable({super.key});

  @override
  GameTableState createState() => GameTableState();
}

class GameTableState extends State<GameTable> {
  final dbRef = FirebaseDatabase.instance.ref();
  // Needed for the first build
  // ignore: avoid_init_to_null
  late DataSnapshot? _data = null;

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

            final teamsData = _data?.child('teams').value as Map<String, dynamic>;
            final matchesData = _data!.child('matches');

            final game = _gameFilter ? otherGameId : defaultGameId;
            return Column(
              children: buildTables(teamsData, matchesData, game),
            );
          },
        )
      ]
    );
  }
}

List<DataTable> buildTables(Map<String, dynamic> teams, DataSnapshot matches, String game) {
  final teamsA = <String, dynamic>{};
  final teamsB = <String, dynamic>{};
  teams.forEach((teamId, teams) {
    if (teamId.contains('A')) {
      teamsA[teamId] = teams;
    } else if (teamId.contains('B')) {
      teamsB[teamId] = teams;
    }
  });
  final groupAMatches = matches.child('groupA').child(game).value as Map<String, dynamic>;
  final groupBMatches = matches.child('groupB').child(game).value as Map<String, dynamic>;
  final rowsA = getRows(teamsA, groupAMatches);
  final rowsB = getRows(teamsB, groupBMatches);
  final groupATable = buildGroupTable(rowsA, 'Group A');
  final groupBTable = buildGroupTable(rowsB, 'Group B');
  return [groupATable, groupBTable];
}

DataTable buildGroupTable(List<DataRow> rows, String group) {
  return DataTable(
    columns: [
      DataColumn(label: Text(group)),
      //DataColumn(label: Text('R'), tooltip: 'Elo Rating'),
      const DataColumn(label: Text('W'), tooltip: 'Wins'),
      const DataColumn(label: Text('L'), tooltip: 'Losses'),
      const DataColumn(label: Text('PD'), tooltip: 'Points Difference'),
    ],
    rows: rows
  );
}

List<DataRow> getRows(Map<String, dynamic> teams, Map<String, dynamic> matches) {
  final rows = teams.entries.map((entry) {
    final teamData = entry.value;
    final teamId = entry.key;

    int wins = 0;
    int losses = 0;
    int draws = 0;
    int pointsFor = 0;
    int pointsAgainst = 0;

    final teamMatches = getTeamMatches(teamId, matches);
    for (final match in teamMatches) {
      final matchData = match.value;
      final homeTeam = matchData['homeTeam'];
      final awayTeam = matchData['awayTeam'];
      final homeScore = int.tryParse(matchData['homeScore'] ?? '');
      final awayScore = int.tryParse(matchData['awayScore'] ?? '');

      if (homeScore == null || awayScore == null) {
        continue;
      }

      if (homeTeam == teamId) {
        if (homeScore > awayScore) {
          wins++;
        } else if (homeScore < awayScore) {
          losses++;
        } else {
          draws++;
        }
        pointsFor += homeScore;
        pointsAgainst += awayScore;
      } else if (awayTeam == teamId) {
        if (homeScore > awayScore) {
          // Loss
          losses++;
        } else if (homeScore < awayScore) {
          // Win
          wins++;
        } else {
          // Draw
          draws++;
        }
        pointsFor += awayScore;
        pointsAgainst += homeScore;
      }
    }

    final cells = <DataCell>[
      DataCell(Tooltip(
        message: teamData['members'].join(', '),
        child: Text(teamData['teamName']),
      )),
      DataCell(Text((wins + draws/2).toString())),
      DataCell(Text((losses + draws/2).toString())),
      DataCell(Text((pointsFor - pointsAgainst).toString())),
    ];
    return DataRow(cells: cells);
  }).toList();

  return sort(rows);
}

// Get all matches for the given teamId
Iterable<dynamic> getTeamMatches(String teamId, Map<String, dynamic> allGroupMatches) {
  final teamMatches = allGroupMatches.entries.where((entry) {
    final matchData = entry.value;
    return matchData['homeTeam'] == teamId || matchData['awayTeam'] == teamId;
  });
  return teamMatches;
}

List<DataRow> sort(List<DataRow> rows) {
  // Sort rows by wins, then by points difference
  rows.sort((a, b) {
    final aWins = parseCell(a.cells[1]);
    final bWins = parseCell(b.cells[1]);
    if (aWins != bWins) {
      return bWins.compareTo(aWins);
    } else {
      final aDiff = parseCell(a.cells[3]);
      final bDiff = parseCell(b.cells[3]);
      return bDiff.compareTo(aDiff);
    }
  });
  return rows;
}

int parseCell(DataCell cell) {
  Text child = cell.child as Text;
  return int.tryParse(child.data!) ?? -1;
}