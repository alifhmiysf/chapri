import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final String _apiKey = 'AIzaSyCPNyBr2PdvLiK396iXihqntyuazxprlcg'; 
  List<Map<String, dynamic>> _reelsVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomShorts();
  }

  Future<void> _fetchRandomShorts() async {
    final String url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&q=%23shorts&type=video&videoDuration=short&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];

        List<Map<String, dynamic>> loadedVideos = [];
        for (var item in items) {
          if (item['id']['videoId'] != null) {
            loadedVideos.add({
              'id': item['id']['videoId'],
              'title': item['snippet']['title'] ?? '',
              'channel': item['snippet']['channelTitle'] ?? '',
            });
          }
        }

        if (mounted) {
          setState(() {
            _reelsVideos = loadedVideos;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error API YouTube: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _reelsVideos.length,
              itemBuilder: (context, index) {
                final video = _reelsVideos[index];
                return ReelItem(
                  key: ValueKey(video['id']),
                  videoId: video['id'],
                  title: video['title'],
                  channel: video['channel'],
                );
              },
            ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final String videoId;
  final String title;
  final String channel;

  const ReelItem({
    super.key,
    required this.videoId,
    required this.title,
    required this.channel,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Konfigurasi untuk versi 10.x menggunakan YoutubePlayerParams
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: false,
        mute: false,
        showFullscreenButton: false,
        loop: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 9 / 16,
          ),
        ),
        Positioned(
          right: 15,
          bottom: 120,
          child: Column(
            children: [
              _buildActionButton(Icons.favorite, "Like", Colors.white),
              const SizedBox(height: 20),
              _buildActionButton(Icons.comment, "Comment", Colors.white),
              const SizedBox(height: 20),
              _buildActionButton(Icons.share, "Share", Colors.white),
            ],
          ),
        ),
        Positioned(
          left: 15,
          bottom: 40,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.channel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const SizedBox(height: 5),
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}