import 'dart:async';

import 'package:csv/csv.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> addInitialMatchesData() async {
  final database = FirebaseDatabase.instance;
  final matchesRef = database.ref().child('matches');

  // Don't add initial matches data if it already exists
  if (!await matchesRef.once().then((DatabaseEvent databaseEvent) {
    return databaseEvent.snapshot.value == null;
  })) {
    return;
  }

  // Read the teams CSV file
  final csvString = await rootBundle.loadString('assets/teams.csv');
  final csvData = const CsvToListConverter(eol: '\n').convert(csvString).skip(1);

  // Get team ids and sort to groups
  final List<String> groupA = [];
  final List<String> groupB = [];
  for (final row in csvData) {
    final teamId = row[0];
    if (teamId.contains('A')) {
      groupA.add(teamId);
    } else if (teamId.contains('B')) {
      groupB.add(teamId);
    }
  }

  // Generate the matches
  List<List<String>> groupAMatches = generateRounds(groupA);
  List<List<String>> groupBMatches = generateRounds(groupB);

  // Add the matches to the database
  persistToDatabase(groupAMatches, "groupA", "fussball", matchesRef);
  persistToDatabase(groupAMatches, "groupA", "marioKart", matchesRef);
  persistToDatabase(groupBMatches, "groupB", "fussball", matchesRef);
  persistToDatabase(groupBMatches, "groupB", "marioKart", matchesRef);
}

List<List<String>> generateRounds(List<String> teams) {
  List<List<List<String>>> rounds = [];

  // Add a bye team if the number of teams is odd
  if (teams.length % 2 != 0) {
    teams.add('Bye');
  }

  // Generate the rounds
  int numRounds = teams.length - 1;
  int halfNumTeams = teams.length ~/ 2;
  for (int i = 0; i < numRounds; i++) {
    List<List<String>> round = [];
    for (int j = 0; j < halfNumTeams; j++) {
      List<String> match = [teams[j], teams[teams.length - j - 1]];
      round.add(match);
    }
    rounds.add(round);
    teams.insert(1, teams.removeLast());
  }

  // Rotate the rounds to alternate home and away games
  for (int i = 0; i < rounds.length; i++) {
    if (i % 2 != 0) {
      for (int j = 0; j < rounds[i].length; j++) {
        rounds[i][j].insert(1, rounds[i][j].removeAt(0));
      }
    }
  }

  // Filter matches with a bye team
  rounds = rounds.map((round) {
    return round.where((match) => !match.contains('Bye')).toList();
  }).toList();

  return rounds.expand((round) => round).toList();
}

void persistToDatabase(
  List<List<String>> matches, String group, String game, DatabaseReference dbRef
  ) {
  for (int i = 0; i < matches.length; i++) {
    final matchRef = dbRef.child(group).child(game).child('M$i');
    matchRef.set({
      'homeTeam': matches[i][0],
      'awayTeam': matches[i][1],
    });
  }
}