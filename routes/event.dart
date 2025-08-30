import 'dart:io';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final client = http.Client();

  try {

    final queryParameters = context.request.uri.queryParameters;
    final date = queryParameters['date'];
    final country = queryParameters['country'];

    if (date == null || date.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Please provide a "date" query parameter.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (country == null || country.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Please provide a "country" query parameter.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final prompt = 'What are the special events in $country on $date? Please provide a concise summary.';

    final chatHistory = [
      {'role': 'user', 'parts': [{'text': prompt}]}
    ];
    final payload = {
      'contents': chatHistory,
    };

    const apiKey = '';

    const maxRetries = 3;
    const initialDelay = Duration(seconds: 1);
    http.Response response;

    for (var i = 0; i < maxRetries; i++) {
      try {
        response = await client.post(
          Uri.parse('$geminiApiUrl?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == HttpStatus.ok) {
          final geminiResult = jsonDecode(response.body);
          final generatedText = geminiResult['candidates'][0]['content']['parts'][0]['text'];

          return Response(
            statusCode: HttpStatus.ok,
            body: jsonEncode({
              'date': date,
              'country': country,
              'events': generatedText,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        } else if (response.statusCode == HttpStatus.tooManyRequests) {
          // Implement exponential backoff.
          final delay = initialDelay * (1 << i);
          await Future.delayed(delay);
        } else {
          // For other errors, return the response immediately.
          return Response(
            statusCode: response.statusCode,
            body: response.body,
            headers: {'Content-Type': 'application/json'},
          );
        }
      } on Exception catch (e) {
        // Handle network or other exceptions during the API call.
        if (i == maxRetries - 1) {
          return Response(
            statusCode: HttpStatus.serviceUnavailable,
            body: jsonEncode({'error': 'Failed to connect to the Gemini API after multiple retries: ${e.toString()}'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        final delay = initialDelay * (1 << i);
        await Future.delayed(delay);
      }
    }

    return Response(
      statusCode: HttpStatus.serviceUnavailable,
      body: jsonEncode({'error': 'Failed to get a response from the Gemini API after multiple retries.'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'An unexpected error occurred: ${e.toString()}'}),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    client.close();
  }
}
