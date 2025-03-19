import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = "http://10.0.2.2:8000"; // Replace with your API URL

  Future<String> chatWithAI(String prompt, String userId) async {
    try {
      Response response = await _dio.post(
        "$baseUrl/chat/",
        data: {"prompt": prompt, "user_id": userId},
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      return response.data["response"];
    } catch (e) {
      print("Error: $e");
      return "Error connecting to AI";
    }
  }
}
