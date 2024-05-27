import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_akhir_tpm_123210060/Service/DatabaseHelper.dart';
import 'package:tugas_akhir_tpm_123210060/Model/User.dart';
import 'package:tugas_akhir_tpm_123210060/Page/Home.dart';
import 'package:tugas_akhir_tpm_123210060/Page/Register.dart';
import 'package:tugas_akhir_tpm_123210060/Page/SelectTeam.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Home(),
        ),
      );
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final dbHelper = DatabaseHelper.instance;

      User? user = await dbHelper.readUserByUsername(_usernameController.text);

      if (user != null) {
        if (generateMd5(_passwordController.text) == user.password) {
          if (user.id_favorite_team == '') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SelectTeam(username: user.username)));
          } else {
            await _saveLoginStatus(true, user.username);

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => Theme(
              data: ThemeData(
                dialogBackgroundColor: Colors.red[900], // Warna latar belakang dialog
              ),
              child: AlertDialog(
                title: Text('Error', style: TextStyle(color: Colors.white)),
                content: Text('Username or password is incorrect or not registered. Try again.', style: TextStyle(color: Colors.white)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => Theme(
            data: ThemeData(
              dialogBackgroundColor: Colors.red[900], // Warna latar belakang dialog
            ),
            child: AlertDialog(
              title: Text('Error', style: TextStyle(color: Colors.white)),
              content: Text('Username or password is incorrect or not registered. Try again.', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveLoginStatus(bool isLoggedIn, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    await prefs.setString('username', username);
  }

  String generateMd5(String input) {
    var bytes = utf8.encode(input); // encode the input string to bytes
    var digest = md5.convert(bytes); // hash the bytes using MD5
    return digest.toString(); // convert the hash to a hex string
  }

  Widget buildTextField(String hint, bool obscureText, TextEditingController controller, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcATop),
                      child: Image.network(
                        'https://webstoriess.enkosa.com/wp-content/uploads/2024/01/Download-Logo-BRI-Liga-1-PNG.png',
                        height: 200,
                        width: 200,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 30),
                    if (_errorMessage.isNotEmpty)
                      Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 14)),
                    SizedBox(height: 20),
                    buildTextField('Username', false, _usernameController, Icons.person,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        }
                    ),
                    SizedBox(height: 20),
                    buildTextField('Password', true, _passwordController, Icons.lock,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        }
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Log in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Register()),
                        );
                      },
                      child: Text("Don't have an account? Register", style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.white],
          begin: Alignment.center,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}