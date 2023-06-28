import 'dart:async';

import 'package:csv/csv.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> addInitialTeamData() async {
  final database = FirebaseDatabase.instance;
  final teamsRef = database.ref().child('teams');

  // Don't add initial team data if it already exists
  if (!await teamsRef.once().then((DatabaseEvent databaseEvent) {
    return databaseEvent.snapshot.value == null;
  })) {
    return;
  }

  // Read the CSV file
  final csvString = await rootBundle.loadString('assets/teams.csv');
  final csvData = const CsvToListConverter(eol: '\n').convert(csvString).skip(1);

  // Add each team to the database
  for (final row in csvData) {
    final teamId = row[0];
    final teamMembers = { for (var member in row.sublist(1)) member };
    final teamRef = teamsRef.child(teamId);
    teamRef.set({'teamName': teamId, 'members': teamMembers});
  }
}
