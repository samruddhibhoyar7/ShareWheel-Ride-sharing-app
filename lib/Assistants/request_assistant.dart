import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> receiveRequest(String url) async {
    try {
      http.Response httpResponse = await http.get(
        Uri.parse(url),
          headers: {
      'X-RapidAPI-Key': 'ca121e8650msh519870ceb7c8f64p1aa2b7jsne4607d7adc52',
      'X-RapidAPI-Host': 'geoapify-address-autocomplete.p.rapidapi.com',
      }
      );

      if (httpResponse.statusCode == 200) {
        String responseData = httpResponse.body;
        var decodeResponseData = jsonDecode(responseData);
        return decodeResponseData;
      } else {
        return "Error Occurred. Failed. No Response.";
      }
    } catch (exp) {
      return "Error Occurred. Failed. No Response.";
    }
  }
}
