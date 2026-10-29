import 'package:serverpod_auth_idp_server/core.dart';

/// JWT refresh. On the unauthenticated exception list: it accepts a refresh
/// token instead of a session.
class JwtRefreshEndpoint extends RefreshJwtTokensEndpoint {}
