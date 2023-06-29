import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TeamsTable extends StatefulWidget {
  const TeamsTable({super.key});

  @override
  TeamsTableState createState() => TeamsTableState();
}

class TeamsTableState extends State<TeamsTable> {
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

        final rows = _teamsData.entries.map((entry) {
          final teamId = entry.key;
          final teamName = entry.value['teamName'] as String;
          final membersList = entry.value['members'] as List<dynamic>;
          final members = membersList.join(', ');
          return DataRow(
            cells: [
              DataCell(
                TextField(
                  controller: TextEditingController(text: teamName),
                  onChanged: (newTeamName) {
                    teamsRef.child(teamId).update({'teamName': newTeamName});
                  },
                ),
              ),
              DataCell(Text(members)),
            ],
          );
        }).toList();

        return DataTable(
          columns: const [
            DataColumn(label: Text('Team Name')),
            DataColumn(label: Text('Members')),
          ],
          rows: rows,
        );
      },
    );
  }
}