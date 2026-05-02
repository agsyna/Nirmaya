import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://nirmaya-api.vercel.app/api/v1/auth/register/patient');
  final body = jsonEncode({
    "name": "Mayank",
    "email": "mayank.test2@example.com",
    "password": "StrongPass123!",
    "age": 21,
    "gender": "male",
    "bloodGroup": "O+",
    "height": 170.0,
    "weight": 85.0
  });

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');
  } catch (e) {
    print('ERROR: $e');
  }
}
