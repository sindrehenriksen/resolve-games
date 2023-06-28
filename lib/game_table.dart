import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class GameTableWidget extends StatefulWidget {
  const GameTableWidget({super.key});

  @override
  GameTableWidgetState createState() => GameTableWidgetState();
}

class GameTableWidgetState extends State<GameTableWidget> {
  final teamsRef = FirebaseDatabase.instance.ref().child('teams');
  late Map<String, dynamic> _teamsData;

  @override
  void initState() {
    super.initState();
    _teamsData = Map<String, dynamic>();
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

        final rows = _teamsData.entries.map((entry) {
          final teamData = entry.value;
          final cells = <DataCell>[
            DataCell(Text(teamData['teamName'])),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
            DataCell(Text('TBD')),
          ];

          return DataRow(cells: cells);
        }).toList();

        return DataTable(
          columns: const [
            DataColumn(label: Text('Team')),
            //DataColumn(label: Text('R'), tooltip: 'Elo Rating'),
            DataColumn(label: Text('GP'), tooltip: 'Games Played'),
            DataColumn(label: Text('W'), tooltip: 'Wins'),
            DataColumn(label: Text('L'), tooltip: 'Losses'),
            DataColumn(label: Text('PD'), tooltip: 'Points Difference'),
            DataColumn(label: Text('PF'), tooltip: 'Points For'),
            DataColumn(label: Text('PA'), tooltip: 'Points Against'),
          ],
          rows: rows
        );
      },
    );
  }
}
