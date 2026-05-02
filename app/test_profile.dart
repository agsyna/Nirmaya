import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://nirmaya-api.vercel.app/api/v1/patient/me');
  final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjNDQxNzZlNy00ODU5LTQzODUtYTdlYS00MTY2MjVjYTllNTciLCJlbWFpbCI6Im1heWFuay50ZXN0MkBleGFtcGxlLmNvbSIsInJvbGUiOiJwYXRpZW50IiwiaWF0IjoxNzc3NzI3MDQ5LCJleHAiOjE3NzgzMzE4NDl9.ncOfTGC2-tTJ-eX0ISqiKyB_aKTwNmBEvBWqAZB_nSM';

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');
  } catch (e) {
    print('ERROR: $e');
  }
}
