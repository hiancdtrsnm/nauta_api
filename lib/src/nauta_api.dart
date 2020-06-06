import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:beautifulsoup/beautifulsoup.dart';

import 'package:nauta_api/src/utils/exceptions.dart';

import '../nauta_api.dart';

class SessionObject {
  String login_action;
  String csrfhw;
  String wlanuserip;
  String attribute_uuid;

  Dio requests_session;
  CookieJar requests_session_cookie;

  SessionObject({
    this.login_action,
    this.csrfhw,
    this.wlanuserip,
  }) {
    create_requests_session();
  }

  void create_requests_session() {
    requests_session = Dio();
    requests_session_cookie = CookieJar();
    requests_session.interceptors.add(CookieManager(requests_session_cookie));
  }

  bool is_logged_in() {
    return (attribute_uuid != null);
  }
}

class NautaProtocol {
  static final CHECK_PAGE = "http://www.cubadebate.cu";

  static SessionObject session;

  static Map<String, String> _get_inputs(Beautifulsoup form_soup) {
    var inputs = form_soup.find_all('input');

    var data = Map<String, String>();

    var entries = inputs
        .map((e) => MapEntry(e.attributes['name'], e.attributes['value']));

    data.addEntries(entries);

    return data;
  }

  static Future<bool> is_connected() async {
    var r = await Dio().get(CHECK_PAGE);

    return !(r.data.toString().contains('secure.etecsa.net'));
  }

  static bool is_logged_in() {
    return (session != null && session.is_logged_in());
  }

  static Future<SessionObject> create_session() async {
    if (await is_connected()) {
      if (is_logged_in()) {
        throw NautaPreLoginException("Hay una session abierta");
      } else {
        throw NautaPreLoginException("Hay una conexion activa");
      }
    }

    session = SessionObject();

    var resp = await session.requests_session.get('http://1.1.1.1/');

    if (resp.statusCode != 200) {
      throw NautaPreLoginException('Failed to create session');
    }

    var soup = Beautifulsoup(resp.data);
    var action = soup('form').attributes['action'];
    var data = _get_inputs(soup);

    // Now go to the login page
    resp = await session.requests_session.post(action,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType));

    soup = Beautifulsoup(resp.data);

    session.login_action = soup.find_all('form')[1].attributes['action'];
    data = _get_inputs(soup);

    session.csrfhw = data['CSRFHW'];
    session.wlanuserip = data['wlanuserip'];

    return session;
  }

  static Future<String> login(
      SessionObject session, String username, String password) async {
    print(session.login_action);

    var r = await session.requests_session.post(session.login_action,
        data: {
          "CSRFHW": session.csrfhw,
          "wlanuserip": session.wlanuserip,
          "username": username,
          "password": password
        },
        options: Options(contentType: Headers.formUrlEncodedContentType));

    print(r.data);
    print(session.requests_session_cookie
        .loadForRequest(Uri.parse('https://secure.etecsa.net:8443/')));
    print(r.statusMessage);
    print(r.statusCode);

    return 'lalalalala';
  }
}

class NautaClient {
  final String user;
  final String password;
  SessionObject session;

  NautaClient({this.user, this.password});

  void init_session() async {
    session = await NautaProtocol.create_session();
  }

  bool is_logged_in() {
    return NautaProtocol.is_logged_in();
  }

  void login() async {
    if (session == null) {
      await init_session();
    }

    session.attribute_uuid = await NautaProtocol.login(session, user, password);
  }
}
