import 'dart:convert';
import 'dart:io';


import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context,String date) async {

  // if (context.request.method != HttpMethod.post) {
  //   return Response(statusCode: HttpStatus.methodNotAllowed);
  // }

  try {
    // final body = await context.request.json();
    // final date = body['date'] as String;

    if (date.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Please provide a "date" in the request body.'}),
      );
    }
    // const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    final prompt = 'What are the special events in India on $date? Please provide a concise summary.';

    final chatHistory = [
      {'role': 'user', 'parts': [{'text': prompt}]}
    ];
    final payload = {
      'contents': chatHistory,
    };

    const apiKey = 'AIzaSyAz0ov7AMgJIHAXl0hSxbky-0OTR0VWkss';
    const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(apiUrl),
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
          'events': generatedText,
        }),
      );
    } else {
      return Response(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
