import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:requests/requests.dart';

import 'package:nauta_api/src/utils/exceptions.dart';

class SessionObject {
  String loginAction;
  String csrfhw;
  String wlanuserip;
  String attributeUuid;

  bool isLoggedIn() {
    return (attributeUuid != null);
  }
}

class NautaProtocol {
  static const CHECK_PAGE = "http://www.cubadebate.cu";

  static SessionObject session;

  static Map<String, String> _getInputs(Beautifulsoup formSoup) {
    var inputs = formSoup.find_all('input');

    var data = Map<String, String>();

    var entries = inputs
        .map((e) => MapEntry(e.attributes['name'], e.attributes['value']));

    data.addEntries(entries);

    return data;
  }

  static Future<bool> isConnected() async {
    var r = await Requests.get(CHECK_PAGE);

    return !(r.content().contains('secure.etecsa.net'));
  }

  static bool isLoggedIn() {
    return (session != null && session.isLoggedIn());
  }

  static Future<SessionObject> createSession() async {
    if (await isConnected()) {
      if (isLoggedIn()) {
        throw NautaPreLoginException("Hay una session abierta");
      } else {
        throw NautaPreLoginException("Hay una conexion activa");
      }
    }

    session = SessionObject();

    var resp = await Requests.get('http://1.1.1.1/');

    if (resp.statusCode != 200) {
      throw NautaPreLoginException('Failed to create session');
    }

    var soup = Beautifulsoup(resp.content());
    var action = soup('form').attributes['action'];
    var data = _getInputs(soup);

    // Now go to the login page
    resp = await Requests.post(action,
        body: data, bodyEncoding: RequestBodyEncoding.FormURLEncoded);

    soup = Beautifulsoup(resp.content());

    session.loginAction = soup.find_all('form')[1].attributes['action'];
    data = _getInputs(soup);

    session.csrfhw = data['CSRFHW'];
    session.wlanuserip = data['wlanuserip'];

    return session;
  }

  static Future<String> login(
      SessionObject session, String username, String password) async {
    var r = await Requests.post(session.loginAction,
        body: {
          "CSRFHW": session.csrfhw,
          "wlanuserip": session.wlanuserip,
          "username": username,
          "password": password
        },
        bodyEncoding: RequestBodyEncoding.FormURLEncoded);

    print(r.statusCode);
    print(r.headers);
    r.raiseForStatus();
    print(r.content());
    print(r.url);

    return 'lalalalala';
  }
}

class NautaClient {
  final String user;
  final String password;
  SessionObject session;

  NautaClient({this.user, this.password});

  Future<void> initSession() async {
    session = await NautaProtocol.createSession();
  }

  bool isLoggedIn() {
    return NautaProtocol.isLoggedIn();
  }

  Future<void> login() async {
    if (session == null) {
      await initSession();
    }

    session.attributeUuid = await NautaProtocol.login(session, user, password);
  }
}
