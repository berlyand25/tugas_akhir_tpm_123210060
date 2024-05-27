class TeamMatch{
  String time;
  final String home_club;
  final String club_logo_home;
  final String score;
  final String club_logo_away;
  final String away_club;
  final String competitions;

  TeamMatch({
    required this.time,
    required this.home_club,
    required this.club_logo_home,
    required this.score,
    required this.club_logo_away,
    required this.away_club,
    required this.competitions,
  });

  factory TeamMatch.fromJson(Map<String, dynamic> json) {
    return TeamMatch(
      time: json['time'], 
      home_club: json['home_club'], 
      club_logo_home: json['club_logo_home'], 
      score: json['score'],
      club_logo_away: json['club_logo_away'],
      away_club: json['away_club'],
      competitions: json['competitions'], 
    );
  }
}