import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TablesTab extends StatefulWidget {
  const TablesTab({super.key});

  @override
  TablesTabState createState() => TablesTabState();
}

const List<Widget> tables = <Widget>[
  Text('Total'),
  Text('Fussball'),
  Text('Mario Kart'),
];

const String total = 'total';
const String fussball = 'fussball';
const String marioKart = 'marioKart';

const fussballPDFactor = 4;  // Points difference factor, based on empirical data

const List<String> gameIds = <String>[
  total,
  fussball,
  marioKart,
];

class TablesTabState extends State<TablesTab> {
  final dbRef = FirebaseDatabase.instance.ref();
  // Needed for the first build
  // ignore: avoid_init_to_null
  late DataSnapshot? _data = null;

  final List<bool> _selectedGame = <bool>[true, false, false];  // [total, fussball, mario kart]

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
          children: tables,
        ),
        StreamBuilder<DatabaseEvent>(
          stream: dbRef.onValue.map((event) => event),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _data = (snapshot.data!).snapshot;
            }

            final teamsData = _data?.child('teams').value as Map<String, dynamic>;
            final matchesData = _data!.child('matches');

            final game = gameIds[_selectedGame.indexOf(true)];
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
  final groupAMatches = getMatches(matches, 'groupA', game);
  final groupBMatches = getMatches(matches, 'groupB', game);
  final rowsA = getRows(teamsA, groupAMatches);
  final rowsB = getRows(teamsB, groupBMatches);
  final groupATable = buildGroupTable(rowsA, 'Group A');
  final groupBTable = buildGroupTable(rowsB, 'Group B');
  return [groupATable, groupBTable];
}

List<dynamic> getMatches(DataSnapshot matches, String group, String game) {
  if (game == total) {
    final marioKartMatches = matches.child(group).child(marioKart).value as Map<String, dynamic>;
    final fussballMatches = matches.child(group).child(fussball).value as Map<String, dynamic>;
    fussballMatches.values.forEach((match) {
      final homeScore = int.tryParse(match['homeScore'] ?? '');
      if (homeScore != null) {
        match['homeScore'] = (homeScore * fussballPDFactor).toString();
      }
      final awayScore = int.tryParse(match['awayScore'] ?? '');
      if (awayScore != null) {
        match['awayScore'] = (awayScore * fussballPDFactor).toString();
      }
    });
    return [...marioKartMatches.values, ...fussballMatches.values];
  }
  final matchesData = matches.child(group).child(game).value as Map<String, dynamic>;
  return matchesData.values.toList();
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

List<DataRow> getRows(Map<String, dynamic> teams, List<dynamic> matches) {
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
      final homeTeam = match['homeTeam'];
      final awayTeam = match['awayTeam'];
      final homeScore = int.tryParse(match['homeScore'] ?? '');
      final awayScore = int.tryParse(match['awayScore'] ?? '');

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
Iterable<dynamic> getTeamMatches(String teamId, List<dynamic> allGroupMatches) {
  final teamMatches = allGroupMatches.where((match) {
    return match['homeTeam'] == teamId || match['awayTeam'] == teamId;
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

double parseCell(DataCell cell) {
  Text child = cell.child as Text;
  return double.tryParse(child.data!) ?? -1;
}
