// lib/services/search_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fera_ai_assistant/models/search_result.dart';
import 'package:fera_ai_assistant/utils/constants.dart';

/// Calls the Fera custom search API and returns structured results.
///
/// Endpoint: https://search.fera-search.tech/?q={query}&safesearch=1&categories=general
class SearchService {
  SearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Searches [query] and returns up to [AppConstants.maxSearchResults] items.
  /// Returns an empty [SearchResponse] on failure (so the AI can still answer
  /// without crashing).
  Future<SearchResponse> search(String query) async {
    final uri = Uri.parse(AppConstants.feraSearchUrl(query));

    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.receiveTimeout);

      if (response.statusCode != 200) {
        return SearchResponse(query: query, results: []);
      }

      final body = jsonDecode(response.body);

      // The Fera/SearXNG-compatible API returns { "results": [...] }
      final rawResults = (body['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final results = rawResults
          .take(AppConstants.maxSearchResults)
          .map(SearchResult.fromJson)
          .toList();

      return SearchResponse(query: query, results: results);
    } catch (_) {
      // Network or parse error — degrade gracefully.
      return SearchResponse(query: query, results: []);
    }
  }
}
