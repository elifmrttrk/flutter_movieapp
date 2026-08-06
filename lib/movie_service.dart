import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  final String apiKey = "a75dca30b3b198b905d5ba55375f64a9"; // TMDb API Key
  final String baseUrl = "https://api.themoviedb.org/3";

  Future<List> fetchMovies({
    String query = "",
    String genre = "all",
    int page = 1,
  }) async {
    Uri url;
    if (query.isNotEmpty) {
      url = Uri.parse(
        "$baseUrl/search/movie?api_key=$apiKey&query=$query&language=tr-TR&page=$page",
      );
    } else if (genre != "all") {
      url = Uri.parse(
        "$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genre&language=tr-TR&page=$page",
      );
    } else {
      url = Uri.parse(
        "$baseUrl/movie/popular?api_key=$apiKey&language=tr-TR&page=$page",
      );
    }

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["results"];
    } else {
      throw Exception("Failed to load movies");
    }
  }
}
