import 'package:flutter/material.dart';

class GameTableWidget extends StatelessWidget {
  const GameTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Team')),
        DataColumn(label: Text('R'), tooltip: 'Elo Rating'),
        DataColumn(label: Text('GP'), tooltip: 'Games Played'),
        DataColumn(label: Text('W'), tooltip: 'Wins'),
        DataColumn(label: Text('L'), tooltip: 'Losses'),
        DataColumn(label: Text('PD'), tooltip: 'Points Difference'),
        DataColumn(label: Text('PF'), tooltip: 'Points For'),
        DataColumn(label: Text('PA'), tooltip: 'Points Against'),
      ],
      rows: [
        DataRow(cells: [
          DataCell(Text('Team A')),
          DataCell(Text('TBD')),
          DataCell(Text('2')),
          DataCell(Text('2')),
          DataCell(Text('0')),
          DataCell(Text('7')),
          DataCell(Text('20')),
          DataCell(Text('13')),
        ]),
        DataRow(cells: [
          DataCell(Text('Team B')),
          DataCell(Text('TBD')),
          DataCell(Text('2')),
          DataCell(Text('1')),
          DataCell(Text('1')),
          DataCell(Text('0')),
          DataCell(Text('18')),
          DataCell(Text('18')),
        ]),
        DataRow(cells: [
          DataCell(Text('Team C')),
          DataCell(Text('TBD')),
          DataCell(Text('2')),
          DataCell(Text('0')),
          DataCell(Text('2')),
          DataCell(Text('-7')),
          DataCell(Text('13')),
          DataCell(Text('20')),
        ]),
      ],
    );
  }
}

