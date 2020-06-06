import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:beautifulsoup/beautifulsoup.dart';


/// WORKING and TESTING NOT REAL EXAMPLE

void main() async {
  var dio = Dio();
  var cookieJar = CookieJar();

  dio.interceptors.add(CookieManager(cookieJar));

  Response response = await dio.get('http://1.1.1.1/');

  var soup = Beautifulsoup(response.data);

  print(response.data);

  print(soup('form').attributes);

  var action = soup('form').attributes['action'];

  print(action);

  var inputs = soup.find_all('input');

  var data = Map<String, String>();

  var entries =
      inputs.map((e) => MapEntry(e.attributes['name'], e.attributes['value']));

  data.addEntries(entries);

  print(data);

  var res = await dio.post(action, data: data);

  print(cookieJar.loadForRequest(Uri.parse(action)));

  print(res.data);

  var login_soup = Beautifulsoup(res.data);

  var login_form_inputs = login_soup.find_all('input');

  var login_data = Map<String, String>();

  var login_entries =
      login_form_inputs.map((e) => MapEntry(e.attributes['name'], e.attributes['value']));

  login_data.addEntries(login_entries);

  print(login_data);

  var csrfhw = login_data['CSRFHW'];
  var wlanuserip = data['wlanuserip'];

  print(csrfhw);
  print(wlanuserip);
}
