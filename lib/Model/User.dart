class User{
  final int? id;
  final String username;
  final String password;
  final String id_favorite_team;
  final String favorite_team;
  final String favorite_team_logo;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.id_favorite_team,
    required this.favorite_team,
    required this.favorite_team_logo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'id_favorite_team': id_favorite_team,
      'favorite_team': favorite_team,
      'favorite_team_logo': favorite_team_logo,
    };
  }
}