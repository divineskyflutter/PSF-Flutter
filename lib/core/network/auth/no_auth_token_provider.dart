import 'auth_token_provider.dart';

/// Every endpoint this app calls today identifies the caller by
/// `memberId` in the request body, not a bearer token (see
/// [AuthTokenProvider] — there is no real login/session flow wired up
/// yet, so every request already goes through with `requireToken: false`).
///
/// This is the shared "no token available" implementation used to build a
/// [NetworkCaller] wherever a feature binding needs one of its own — kept
/// as a real, reusable class instead of every binding redeclaring the
/// same private stub (as `AuthBinding`'s `_PublicAuthTokenProvider` does
/// today). Swap this out for a real token-backed implementation once the
/// backend has an actual authenticated session to attach.
class NoAuthTokenProvider implements AuthTokenProvider {
  const NoAuthTokenProvider();

  @override
  String? getToken() => null;
}
