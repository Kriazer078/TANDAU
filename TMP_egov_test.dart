// ignore_for_file: avoid_print, file_names

import 'dart:convert';
import 'dart:io';

void main() async {
  print('Testing Egov API v4 without API key...');
  
  final url1 = Uri.parse('https://data.egov.kz/api/v4/higher_education_org1').replace(queryParameters: {'source': '{"size":2}'});
  
  try {
    final httpClient = HttpClient();
    
    // Test dataset 1
    print('Requesting: $url1');
    final request = await httpClient.getUrl(url1);
    request.headers.add('Accept', 'application/json');
    request.headers.add('User-Agent', 'Dart/3.0 (TANDAU App)');
    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();
    print('Status Code: ${response.statusCode}');
    print('Response (1st 500 chars): ${stringData.length > 500 ? stringData.substring(0, 500) : stringData}');

    // Test dataset 2
    final url2 = Uri.parse('https://data.egov.kz/api/v4/bilim_beru_dengeileri_boiynsha1').replace(queryParameters: {'source': '{"size":2}'});
    print('\nRequesting: $url2');
    final request2 = await httpClient.getUrl(url2);
    request2.headers.add('Accept', 'application/json');
    request2.headers.add('User-Agent', 'Dart/3.0 (TANDAU App)');
    final response2 = await request2.close();
    final stringData2 = await response2.transform(utf8.decoder).join();
    print('Status Code: ${response2.statusCode}');
    print('Response (1st 500 chars): ${stringData2.length > 500 ? stringData2.substring(0, 500) : stringData2}');

    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
