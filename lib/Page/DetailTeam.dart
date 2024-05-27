import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir_tpm_123210060/Model/TeamProfile.dart';

class DetailTeam extends StatefulWidget {
  final String id;
  final String team_venue;

  DetailTeam({required this.id, required this.team_venue});

  @override
  _DetailTeamState createState() => _DetailTeamState(id: this.id, team_venue: this.team_venue);
}

class _DetailTeamState extends State<DetailTeam> {
  final String id;
  final String team_venue;
  TeamProfile? team;

  _DetailTeamState({required this.id, required this.team_venue});

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response1 = await http.get(Uri.parse('https://ligaindonesia-api.vercel.app/api/v1/team/profile/' + id));

    if (response1.statusCode == 200) {
      dynamic data = jsonDecode(response1.body)['data'];

      setState(() {
        team = TeamProfile.fromJson(data);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: (team != null) 
        ? Text(team!.team_name.substring(0,  min(team!.team_name.length, 19)), 
            style: TextStyle(color: Colors.white)) 
        : Text('Team Name', 
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: (team != null) ?
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(
                team!.team_logo,
                width: 200,
                height: 200,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Team Name',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      team!.team_name,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Team Founded',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      (team_venue == team!.team_venue) ? team!.team_founded : team!.team_venue,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Team Venue',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      team_venue,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
                  child: Divider(color: Colors.blue[900], thickness: 2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Game Play',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      team!.game_play,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Game Win',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      team!.game_win,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Game Draw',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      team!.game_draw,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Game Lose',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      team!.game_lose,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
                  child: Divider(color: Colors.blue[900], thickness: 2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      (team!.description != '') ? team!.description : 'No Description',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ) : Text('No Team Data'),
        ),
      ),
    );
  }
}