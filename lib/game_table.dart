import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class GameTable extends StatefulWidget {
  const GameTable({super.key});

  @override
  GameTableState createState() => GameTableState();
}

class GameTableState extends State<GameTable> {
  final teamsRef = FirebaseDatabase.instance.ref().child('teams');
  late Map<String, dynamic> _teamsData;

  @override
  void initState() {
    super.initState();
    _teamsData = <String, dynamic>{};
    teamsRef.once().then((DatabaseEvent databaseEvent) {
      setState(() {
        _teamsData = databaseEvent.snapshot.value as Map<String, dynamic>;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: teamsRef.onValue.map((event) => event),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _teamsData = (snapshot.data!).snapshot.value as Map<String, dynamic>;
        }

        final teamsDataA = <String, dynamic>{};
        final teamsDataB = <String, dynamic>{};

        _teamsData.forEach((teamId, teamData) {
          if (teamId.contains('A')) {
            teamsDataA[teamId] = teamData;
          } else if (teamId.contains('B')) {
            teamsDataB[teamId] = teamData;
          }
        });

        final rowsA = teamsDataA.entries.map((entry) {
          final teamData = entry.value;
          final cells = <DataCell>[
            DataCell(Tooltip(
              message: teamData['members'].join(', '),
              child: Text(teamData['teamName']),
            )),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
          ];

          return DataRow(cells: cells);
        }).toList();

        final rowsB = teamsDataB.entries.map((entry) {
          final teamData = entry.value;
          final cells = <DataCell>[
            DataCell(Tooltip(
              message: teamData['members'].join(', '),
              child: Text(teamData['teamName']),
            )),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
          ];

          return DataRow(cells: cells);
        }).toList();

        return Column(
          children: [
            DataTable(
              columns: const [
                DataColumn(label: Text('Group A')),
                //DataColumn(label: Text('R'), tooltip: 'Elo Rating'),
                DataColumn(label: Text('P'), tooltip: 'Points'),
                DataColumn(label: Text('GP'), tooltip: 'Games Played'),
                DataColumn(label: Text('W'), tooltip: 'Wins'),
                DataColumn(label: Text('L'), tooltip: 'Losses'),
                DataColumn(label: Text('PD'), tooltip: 'Points Difference'),
                DataColumn(label: Text('PF'), tooltip: 'Points For'),
                DataColumn(label: Text('PA'), tooltip: 'Points Against'),
              ],
              rows: rowsA
            ),
            DataTable(
              columns: const [
                DataColumn(label: Text('Group B')),
                //DataColumn(label: Text('R'), tooltip: 'Elo Rating'),
                DataColumn(label: Text('P'), tooltip: 'Points'),
                DataColumn(label: Text('GP'), tooltip: 'Games Played'),
                DataColumn(label: Text('W'), tooltip: 'Wins'),
                DataColumn(label: Text('L'), tooltip: 'Losses'),
                DataColumn(label: Text('PD'), tooltip: 'Points Difference'),
                DataColumn(label: Text('PF'), tooltip: 'Points For'),
                DataColumn(label: Text('PA'), tooltip: 'Points Against'),
              ],
              rows: rowsB
            ),
          ],
        );
      },
    );
  }
}
