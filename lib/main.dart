import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
// This import is crucial for web-specific download functionality
import 'dart:html' as html;

void main() {
  runApp(const PodcastDownloaderApp());
}

class PodcastDownloaderApp extends StatelessWidget {
  const PodcastDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podcast Downloader',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controller for the RSS feed URL input
  // We'll pre-fill it with a demo feed.
  final TextEditingController _rssController = TextEditingController(
    text: 'https://feeds.podcastindex.org/pc20.xml',
  );

  RssFeed? _feed;
  bool _isLoading = false;
  String? _error;

  // Base URL for the CORS proxy
  final String _corsProxyUrl = 'https://api.allorigins.win/raw?url=';

  /// Fetches and parses the RSS feed from the URL in the text controller.
  Future<void> _fetchFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _feed = null;
    });

    final url = _rssController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _error = 'Please enter an RSS feed URL';
        _isLoading = false;
      });
      return;
    }

    // We must use a CORS proxy for the web app to be ableto fetch the feed.
    final proxiedUrl = '$_corsProxyUrl${Uri.encodeComponent(url)}';

    try {
      final response = await http.get(Uri.parse(proxiedUrl));

      if (response.statusCode == 200) {
        // Successfully fetched the feed
        final feed = RssFeed.parse(response.body);
        setState(() {
          _feed = feed;
          _isLoading = false;
        });
      } else {
        // Handle HTTP errors
        setState(() {
          _error = 'Failed to fetch feed: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle other errors (network, parsing, etc.)
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  /// Triggers a browser download for the given podcast episode.
  void _downloadEpisode(RssItem item) {
    final mp3Url = item.enclosure?.url;
    if (mp3Url == null) {
      // Show an error if no MP3 URL is found in the enclosure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No MP3 URL found for this episode.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Sanitize the title to create a valid filename
    final safeTitle = item.title?.replaceAll(RegExp(r'[^\w\s\.-]'), '').trim() ?? 'podcast_episode';
    final filename = '$safeTitle.mp3';

    /*
     * WEB DOWNLOAD LOGIC:
     * We can't just download the `mp3Url` directly, as the browser's
     * CORS policy would block it, and the `download` attribute would be ignored.
     * * SOLUTION:
     * We create a download link pointing to the *proxied* URL.
     * This makes the browser treat it as a file from the same origin,
     * allowing the `download` attribute to work correctly.
    */
    
    // 1. Create the proxied download URL
    final proxiedDownloadUrl = '$_corsProxyUrl${Uri.encodeComponent(mp3Url)}';

    // 2. Create an invisible anchor (`<a>`) element
    final anchor = html.AnchorElement(href: proxiedDownloadUrl)
      ..setAttribute('download', filename); // 3. Set the desired filename

    // 4. Programmatically click the link to start the download
    anchor.click();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download: $filename'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Podcast Downloader'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- URL Input Field ---
                TextField(
                  controller: _rssController,
                  decoration: InputDecoration(
                    labelText: 'Enter Podcast RSS Feed URL',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _rssController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Fetch Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.rss_feed),
                    label: const Text('Fetch Feed'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _isLoading ? null : _fetchFeed,
                  ),
                ),
                const SizedBox(height: 20),

                // --- Content Area (Loading, Error, or List) ---
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main content area based on the current state.
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_feed == null) {
      return const Center(
        child: Text(
          'Enter an RSS feed URL above and click "Fetch Feed".',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // --- Podcast Feed Display ---
    final items = _feed?.items ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No episodes found in this feed.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Feed Title ---
        Text(
          _feed?.title ?? 'Podcast Feed',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(_feed?.description ?? ''),
        const Divider(height: 20, thickness: 1),

        // --- Episode List ---
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final hasMp3 = item.enclosure?.url != null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(item.title ?? 'No Title'),
                  subtitle: Text(
                    item.pubDate?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_for_offline),
                    color: Theme.of(context).primaryColor,
                    // Disable the button if no MP3 URL is found
                    onPressed: hasMp3 ? () => _downloadEpisode(item) : null,
                    tooltip: hasMp3
                        ? 'Download MP3'
                        : 'No MP3 enclosure found',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
