class TeamProfile{
  final String team_name;
  final String team_founded;
  final String team_logo;
  final String team_venue;
  final String game_play;
  final String game_win;
  final String game_draw;
  final String game_lose;
  final String description;

  TeamProfile({
    required this.team_name,
    required this.team_founded,
    required this.team_logo,
    required this.team_venue,
    required this.game_play,
    required this.game_win,  
    required this.game_draw,
    required this.game_lose,
    required this.description,
  });

  factory TeamProfile.fromJson(Map<String, dynamic> json) {
    return TeamProfile(
      team_name: json['team_name'], 
      team_founded: json['team_founded'], 
      team_logo: json['team_logo'], 
      team_venue: json['team_venue'],
      game_play: json['game_play'],
      game_win: json['game_win'],
      game_draw: json['game_draw'], 
      game_lose: json['game_lose'],
      description: json['description'],
    );
  }
}