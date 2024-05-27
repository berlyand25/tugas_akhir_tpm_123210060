class Team{
  final String team_id;
  final String team_name;
  final String team_venue;
  final String team_logo;

  Team({
    required this.team_id,
    required this.team_name,
    required this.team_venue,
    required this.team_logo,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      team_id: json['team_id'], 
      team_name: json['team_name'], 
      team_venue: json['team_venue'], 
      team_logo: json['team_logo'], 
    );
  }
}