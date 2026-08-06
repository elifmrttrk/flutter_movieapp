import 'package:flutter/material.dart';

class MovieDetailPage extends StatelessWidget {
  final Map movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie['title'] ?? 'Film Detayı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Ana menüye dön
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            if (movie['poster_path'] != null)
              SizedBox(
                width: 150,
                child: Image.network(
                  "https://image.tmdb.org/t/p/w500${movie['poster_path']}",
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 150,
                height: 225,
                color: Colors.grey,
                child: const Center(child: Text("No Image")),
              ),

            const SizedBox(width: 16),

            // Bilgi
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      movie['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Detaylar
                    Text(
                      "⭐ Puan: ${movie['vote_average'] ?? '0'}\n"
                      "👀 İzlenme: ${movie['popularity']?.toInt() ?? '0'}\n"
                      "Yayın Tarihi: ${movie['release_date'] ?? 'Bilinmiyor'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Özet
                    Text(
                      movie['overview'] ?? "Özet mevcut değil.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
