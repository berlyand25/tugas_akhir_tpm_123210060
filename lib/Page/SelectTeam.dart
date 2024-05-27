import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_akhir_tpm_123210060/Service/DatabaseHelper.dart';
import 'package:tugas_akhir_tpm_123210060/Model/User.dart';
import 'package:tugas_akhir_tpm_123210060/Model/Team.dart';
import 'package:tugas_akhir_tpm_123210060/Page/Home.dart';

class SelectTeam extends StatefulWidget {
  final String username;

  SelectTeam({required this.username});

  @override
  _SelectTeamState createState() => _SelectTeamState(username: username);
}

class _SelectTeamState extends State<SelectTeam> {
  List<Team> teams = [];
  String username = '';

  _SelectTeamState({required this.username});

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response1 = await http.get(Uri.parse('https://ligaindonesia-api.vercel.app/api/v1/teams'));

    if (response1.statusCode == 200) {
      List<dynamic> data = jsonDecode(response1.body)['data'];

      setState(() {
        teams = data.map((team) => Team.fromJson(team)).toList();
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
        title: Text('Favourite Team', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: true,
      ),
      body: TeamGrid(teams: teams, username: username),
      backgroundColor: Colors.blue[900],
    );
  }
}

class TeamGrid extends StatelessWidget {
  final List<Team> teams;
  final String username;

  TeamGrid({required this.teams, required this.username});

  Future<void> _selectTeam(BuildContext context, String id_favorite_team, String favorite_team, String favorite_team_logo) async {
    final dbHelper = DatabaseHelper.instance;

    User? registeredUser = await dbHelper.readUserByUsername(username);

    if (registeredUser != null) {
      final newUser = User(
        id: registeredUser.id,
        username: registeredUser.username,
        password: registeredUser.password,
        id_favorite_team: id_favorite_team,
        favorite_team: favorite_team,
        favorite_team_logo: favorite_team_logo,
      );

      await dbHelper.update(newUser);

      await _saveLoginStatus(true, username);

      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
    }
  }

  Future<void> _saveLoginStatus(bool isLoggedIn, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    await prefs.setString('username', username);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Pick your team',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                return TeamCard(
                  name: teams[index].team_name,
                  logoUrl: teams[index].team_logo,
                  onTap: () {
                    _selectTeam(context, teams[index].team_id, teams[index].team_name, teams[index].team_logo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TeamCard extends StatelessWidget {
  final String name;
  final String logoUrl;
  final VoidCallback onTap;

  TeamCard({required this.name, required this.logoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      logoUrl,
                      height: 100,
                      width: 100,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}