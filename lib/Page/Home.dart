import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_akhir_tpm_123210060/Service/DatabaseHelper.dart';
import 'package:tugas_akhir_tpm_123210060/Service/NotificationService.dart';
import 'package:tugas_akhir_tpm_123210060/Model/User.dart';
import 'package:tugas_akhir_tpm_123210060/Page/DetailTeam.dart';
import 'package:tugas_akhir_tpm_123210060/Page/DetailTeamMatch.dart';
import 'package:tugas_akhir_tpm_123210060/Model/Team.dart';
import 'package:tugas_akhir_tpm_123210060/Model/TeamMatch.dart';
import 'package:tugas_akhir_tpm_123210060/Page/Login.dart';
import 'package:tugas_akhir_tpm_123210060/Page/SelectTeam.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProfileScreen(),
    MessagesScreen(),
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 3) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Login(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: (_selectedIndex != 3) ? _widgetOptions.elementAt(_selectedIndex) : Center(child: Text("Log out", style: TextStyle(color: Colors.white))),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue[900],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Team> teams = [];
  List<Team> filteredTeams = [];
  List<TeamMatch> teamMatches = [];
  List<TeamMatch> upcomingMatches = [];
  List<TeamMatch> resultMatches = [];
  String _selectedTimeZone = 'GMT+7';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();

    searchController.addListener(() {
      filterTeams();
    });
  }

  Future<void> fetchData() async {
    final response1 = await http.get(Uri.parse('https://ligaindonesia-api.vercel.app/api/v1/teams'));

    if (response1.statusCode == 200) {
      List<dynamic> data = jsonDecode(response1.body)['data'];

      setState(() {
        teams = data.map((team) => Team.fromJson(team)).toList();
        filteredTeams = teams;
      });
    } else {
      throw Exception('Failed to load data');
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = await prefs.getString('username') ?? '';

    final dbHelper = DatabaseHelper.instance;
    User? user = await dbHelper.readUserByUsername(username);

    final response2 = await http.get(Uri.parse('https://ligaindonesia-api.vercel.app/api/v1/team/match/${user!.id_favorite_team}'));

    if (response2.statusCode == 200) {
      List<dynamic> data = jsonDecode(response2.body)['data'];

      setState(() {
        teamMatches = data.map((teamMatch) => TeamMatch.fromJson(teamMatch)).toList();
        convertDateFormat();
        filterMatches();
        scheduleNotifications();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  void filterTeams() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredTeams = teams.where((team) {
        return team.team_name.toLowerCase().contains(query);
      }).toList();
    });
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
    resultMatches = teamMatches.where((teamMatch) => teamMatch.score != 'vs').toList();

    setState(() {
      _selectedTimeZone = 'GMT+7';
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

      _selectedTimeZone = timeZone;
    });
  }

  String convertTimeZone(String time, String timeZone) {
    DateTime dateTime = DateTime.parse(time);
  
    int offsetHours, GMT = int.parse(_selectedTimeZone[4]);

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

  void scheduleNotifications() {
    final now = DateTime.now();

    for (var match in upcomingMatches) {
      final matchTime = DateTime.parse(match.time);

      if (matchTime.isAfter(now) && matchTime.difference(now).inHours <= 1) {
        // Buat ID unik dari hash kombinasi nama tim dan waktu pertandingan
        final uniqueId = _generateUniqueId(match.home_club, match.away_club, match.time);

        NotificationService().showNotification(
          uniqueId,
          'Upcoming Match',
          '${match.home_club} vs ${match.away_club} at ' + matchTime.toLocal().toString().substring(0,16),
          matchTime.subtract(Duration(minutes: 30)), // Jadwalkan berapa menit sebelum pertandingan
        );
      }
   }
  }

  int _generateUniqueId(String homeTeam, String awayTeam, String matchTime) {
    final data = utf8.encode('$homeTeam$awayTeam$matchTime');
    final hash = md5.convert(data);
    return hash.hashCode;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Liga 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.network(
                  'https://webstoriess.enkosa.com/wp-content/uploads/2024/01/Download-Logo-BRI-Liga-1-PNG.png',
                  height: 50,
                  width: 50,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          DropdownButton<String>(
            value: _selectedTimeZone,
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
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Upcoming Matches',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.black),
                ],  
              ),
              subtitle: (upcomingMatches.isNotEmpty) 
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    upcomingMatches[upcomingMatches.length - 1].time.substring(0, 16),
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Image.network(
                        upcomingMatches[upcomingMatches.length - 1].club_logo_home,
                        height: 50,
                        width: 50,
                      ),
                      Text(
                        upcomingMatches[upcomingMatches.length - 1].score,
                        style: TextStyle(color: Colors.black),
                      ),
                      Image.network(
                        upcomingMatches[upcomingMatches.length - 1].club_logo_away,
                        height: 50,
                        width: 50,
                      ),
                    ],
                  ),
                ],
              ) 
              : Text('No upcoming matches'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTeamMatch(isResult: false),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.0),
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Match Results',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.black),
                ],  
              ),
              subtitle: (resultMatches.isNotEmpty) 
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    resultMatches[0].time.substring(0, 16),
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Image.network(
                        resultMatches[0].club_logo_home,
                        height: 50,
                        width: 50,
                      ),
                      Text(
                        resultMatches[0].score,
                        style: TextStyle(color: Colors.black),
                      ),
                      Image.network(
                        resultMatches[0].club_logo_away,
                        height: 50,
                        width: 50,
                      ),
                    ],
                  ),
                ],
              ) 
              : Text('No match results'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTeamMatch(isResult: true),
                  ),
                );
              },
            ),
          ),
          ListTile(
            title: Text(
              'Clubs',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text('Liga 1 2023/2024 Season', style: TextStyle(color: Colors.white)),
          ),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search teams',
              prefixIcon: Icon(Icons.search, color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.blue[800],
              hintStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredTeams.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  leading: Image.network(
                    filteredTeams[index].team_logo,
                    height: 50,
                    width: 50,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(filteredTeams[index].team_name.substring(0, min(filteredTeams[index].team_name.length, 19))),
                      Icon(Icons.arrow_forward, color: Colors.black),
                    ],  
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailTeam(id: filteredTeams[index].team_id, team_venue: filteredTeams[index].team_venue),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String id_favorite_team = '';
  String favorite_team = '';
  String favorite_team_logo = '';

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username') ?? '';

    final dbHelper = DatabaseHelper.instance;
    User? user = await dbHelper.readUserByUsername(username);

    setState(() {
      this.username = user!.username;
      this.id_favorite_team = user.id_favorite_team;
      this.favorite_team = user.favorite_team;
      this.favorite_team_logo = user.favorite_team_logo;
    });
  }

  void _navigateToSelectTeam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectTeam(username: username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                NetworkImage(
                  'https://projectekno.com/wp-content/uploads/2024/01/87.-PP-Kosong-Retak.jpg',
                  scale: 10,
                ),
              ),
              SizedBox(height: 20),
              Text(
                username,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 20),
              Image.network(
                favorite_team_logo,
                height: 75,
                width: 75,
              ),
              SizedBox(height: 10),
              Text(
                favorite_team,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _navigateToSelectTeam(context),
                child: Text('Edit Favourite Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[900],
                  minimumSize: Size(150, 30), 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  color: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Hai Pak, saya ingin mengucapkan terima kasih atas bimbingan yang diberikan selama mata kuliah Teknologi dan Pemrograman Mobile ini. Namun, saya ingin memberikan sedikit masukan. Bolehkah kuisnya dikurangi sedikit? Terkadang jadwal kuis bertabrakan dengan mata kuliah lain, membuat kami sedikit kerepotan. Tapi, saya sangat menghargai kreativitas dalam menyampaikan materi. Semoga selalu sehat dan sukses, serta terus menjadi dosen yang peduli terhadap mahasiswanya. Oh ya, apakah saya bisa dapat nilai A Pak? Sekadar saran, mungkin Ujian Akhirnya bisa diganti dengan pengumpulan proyek akhir saja, hehe. Terima kasih.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Kesan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  color: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Wuih, belajar TPM bener-bener seru banget! Kadang-kadang panik dikit sih, terutama pas kode programnya warna merah deket-deket deadline. Tapi overall, pengalaman belajarnya keren banget. TPM sangat asyik sekali.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}