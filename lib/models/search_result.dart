// lib/models/search_result.dart

/// A single result item returned by the Fera search API.
class SearchResult {
  final String title;
  final String url;
  final String snippet;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        title: (json['title'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
        snippet: (json['content'] as String?) ??
            (json['snippet'] as String?) ??
            '',
      );

  /// Formats the result as a compact text block to be injected into the AI
  /// prompt as context.
  String toPromptContext() => '• [$title]($url)\n  $snippet';
}

/// Wraps a list of [SearchResult] objects with metadata.
class SearchResponse {
  final String query;
  final List<SearchResult> results;

  const SearchResponse({required this.query, required this.results});

  bool get hasResults => results.isNotEmpty;

  /// Concatenated context string for the AI system prompt.
  String toPromptContext() {
    if (!hasResults) return '';
    final buffer = StringBuffer(
        'Web search results for "$query":\n');
    for (final r in results) {
      buffer.writeln(r.toPromptContext());
    }
    return buffer.toString();
  }
}
