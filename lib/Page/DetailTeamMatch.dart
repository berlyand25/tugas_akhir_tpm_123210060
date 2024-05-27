import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_akhir_tpm_123210060/Service/DatabaseHelper.dart';
import 'package:tugas_akhir_tpm_123210060/Model/User.dart';
import 'package:tugas_akhir_tpm_123210060/Model/TeamMatch.dart';

class DetailTeamMatch extends StatefulWidget {
  final bool isResult;

  DetailTeamMatch({required this.isResult});

  @override
  _DetailTeamMatchState createState() => _DetailTeamMatchState(isResult: this.isResult);
}

class _DetailTeamMatchState extends State<DetailTeamMatch> {
  List<TeamMatch> teamMatches = [];
  List<TeamMatch> upcomingMatches = [];
  List<TeamMatch> resultMatches = [];
  String selectedTimeZone = 'GMT+7';
  bool isResult = false;

  _DetailTeamMatchState({required this.isResult});

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = await prefs.getString('username') ?? '';

    final dbHelper = DatabaseHelper.instance;
    User? user = await dbHelper.readUserByUsername(username);

    final response = await http.get(Uri.parse('https://ligaindonesia-api.vercel.app/api/v1/team/match/${user!.id_favorite_team}'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['data'];

      setState(() {
        teamMatches = data.map((teamMatch) => TeamMatch.fromJson(teamMatch)).toList();
        convertDateFormat();
        filterMatches();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  void convertDateFormat() {
    for (var match in teamMatches) {
        List<String> dateTimeParts = match.time.split(' ');
        String date = dateTimeParts[0];
        String time = dateTimeParts[1];

        List<String> dateParts = date.split('-');
        String day = dateParts[0];
        String month = dateParts[1];
        String year = dateParts[2];

        match.time = year + '-' + month + '-' + day + ' ' + time + ':00';
    }
  }

  void filterMatches() {
    upcomingMatches = teamMatches.where((teamMatch) => teamMatch.score == 'vs').toList();
    upcomingMatches = upcomingMatches.reversed.toList();
    resultMatches = teamMatches.where((teamMatch) => teamMatch.score != 'vs').toList();

    setState(() {
      selectedTimeZone = 'GMT+7';
    });
  }

  void updateMatchTimes(String timeZone) {
    setState(() {
      for (var match in upcomingMatches) {
        match.time = convertTimeZone(match.time, timeZone);
      }

      for (var match in resultMatches) {
        match.time = convertTimeZone(match.time, timeZone);
      }

      selectedTimeZone = timeZone;
    });
  }

  String convertTimeZone(String time, String timeZone) {
    DateTime dateTime = DateTime.parse(time);
  
    int offsetHours, GMT = int.parse(selectedTimeZone[4]);

    switch (timeZone) {
      case 'GMT+1':
        offsetHours = 1-GMT;
        break;
      case 'GMT+7':
        offsetHours = 7-GMT;
        break;
      case 'GMT+8':
        offsetHours = 8-GMT;
        break;
      case 'GMT+9':
        offsetHours = 9-GMT;
        break;
      default:
        offsetHours = 7-GMT;
    }
    
    return dateTime.add(Duration(hours: offsetHours)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: (isResult) 
        ? Text('Match Results', 
            style: TextStyle(color: Colors.white)) 
        : Text('Upcoming Matches', 
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      backgroundColor: Colors.blue[900],
      body: ((isResult && resultMatches.length != 0) || (!isResult) && upcomingMatches.length != 0) ? 
      SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedTimeZone,
              icon: Icon(Icons.arrow_downward, color: Colors.white),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(color: Colors.white),
              dropdownColor: Colors.blue[900],
              underline: Container(
                height: 2,
                color: Colors.white,
              ),
              onChanged: (newValue) {
                updateMatchTimes(newValue!);
              },
              items: <String>['GMT+1', 'GMT+7', 'GMT+8', 'GMT+9']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: (isResult) ? resultMatches.length : upcomingMatches.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (isResult) 
                          ? resultMatches[index].time.substring(0, 16) 
                          : upcomingMatches[index].time.substring(0, 16),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Image.network(
                              (isResult) 
                              ? resultMatches[index].club_logo_home 
                              : upcomingMatches[index].club_logo_home,
                              height: 50,
                              width: 50,
                            ),
                            Text(
                              (isResult) 
                              ? resultMatches[index].score 
                              : upcomingMatches[index].score,
                              style: TextStyle(color: Colors.black),
                            ),
                            Image.network(
                              (isResult) 
                              ? resultMatches[index].club_logo_away 
                              : upcomingMatches[index].club_logo_away,
                              height: 50,
                              width: 50,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ) : Center(child: Text((isResult) ? 'No Match Results' : 'No Upcoming Matches', style: TextStyle(color: Colors.white),)),
    );
  }
}