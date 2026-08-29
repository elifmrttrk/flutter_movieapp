import 'package:flutter/material.dart';
import 'dart:async';
import 'movie_service.dart';
import 'movie_detail_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MovieApp());
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MovieHomePage(),
    );
  }
}

class MovieHomePage extends StatefulWidget {
  const MovieHomePage({super.key});

  @override
  State<MovieHomePage> createState() => _MovieHomePageState();
}

class _MovieHomePageState extends State<MovieHomePage> {
  final MovieService _movieService = MovieService();
  List movies = [];
  List suggestions = [];
  String query = "";
  String selectedCategory = "all";
  String sortBy = "vote_average";
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  Timer? _debounce;

  final categories = {
    "Tümü": "all",
    "Aksiyon": "28",
    "Komedi": "35",
    "Drama": "18",
    "Korku": "27",
    "Romantik": "10749",
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !isLoading &&
          hasMore) {
        _loadMovies();
      }
    });
  }

  void _loadMovies({bool reset = false}) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    if (reset) {
      currentPage = 1;
      hasMore = true;
      movies.clear();
    }

    final results = await _movieService.fetchMovies(
      query: query,
      genre: (query.isEmpty) ? selectedCategory : "all",
      page: currentPage,
    );

    if (results.isEmpty) {
      hasMore = false;
    } else {
      currentPage++;
    }

    results.sort((a, b) {
      double aVal = (sortBy == "vote_average")
          ? a["vote_average"]
          : a["popularity"];
      double bVal = (sortBy == "vote_average")
          ? b["vote_average"]
          : b["popularity"];
      return bVal.compareTo(aVal);
    });

    setState(() {
      movies.addAll(results);
      isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        query = value;
      });

      if (query.isEmpty) {
        setState(() => suggestions = []);
        _loadMovies(reset: true);
        return;
      }

      // Önerileri getir
      final results = await _movieService.fetchMovies(query: query, page: 1);
      setState(() {
        suggestions = results.take(5).toList(); // İlk 5 öneri
      });

      _loadMovies(reset: true);
    });
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        sortBy = value;
      });
      _loadMovies(reset: true);
    }
  }

  void _onCategoryChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedCategory = value;
        query = "";
        suggestions = [];
      });
      _loadMovies(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movie App")),
      body: Column(
        children: [
          // Arama ve filtreler
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Film ara...",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                if (suggestions.isNotEmpty)
                  Flexible(
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final movie = suggestions[index];
                          return ListTile(
                            title: Text(movie["title"] ?? ""),
                            onTap: () {
                              setState(() {
                                query = movie["title"] ?? "";
                                suggestions = [];
                              });
                              _loadMovies(reset: true);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedCategory,
                      items: categories.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.value,
                              child: Text(entry.key),
                            ),
                          )
                          .toList(),
                      onChanged: _onCategoryChanged,
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: sortBy,
                      items: const [
                        DropdownMenuItem(
                          value: "vote_average",
                          child: Text("Puan"),
                        ),
                        DropdownMenuItem(
                          value: "popularity",
                          child: Text("İzlenme"),
                        ),
                      ],
                      onChanged: _onSortChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Film grid
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 300,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: movies.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= movies.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final movie = movies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailPage(movie: movie),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            movie['poster_path'] != null
                                ? "https://image.tmdb.org/t/p/w500${movie['poster_path']}"
                                : "https://via.placeholder.com/150",
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            movie["title"] ?? "No Title",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "⭐ ${movie['vote_average'] ?? 0} | 👀 ${movie['popularity']?.toInt() ?? 0}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
