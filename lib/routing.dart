import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef PageBuilder = Page<dynamic> Function(Uri uri, Map<String, String> pathParams);
typedef PageFactory = Page<dynamic>? Function(Uri uri);

const String pagesRegexGroupName = 'name';

class SimpleRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture<Uri>(Uri.parse(routeInformation.location!));
  }

  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    print('restore route information ${configuration.toString()}');
    return RouteInformation(location: configuration.toString());
  }
}

class SimpleRouterDelegate extends RouterDelegate<Uri> with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  SimpleRouterDelegate({
    GlobalKey<NavigatorState>? navigatorKey,
    Map<String, PageBuilder>? pages,
    this.home,
    this.onGeneratePage,
    this.onUnknownPage,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
      _regexPages = pages == null ? null : _convertsToRegexpMap(pages);

  /// The application's top-level routing table.
  ///
  /// If the app only has one page, then you can specify it using [home] instead.
  ///
  /// If [home] is specified, then it implies an entry in this table for the
  /// [Navigator.defaultRouteName] route (`/`), and it is an error to
  /// redundantly provide such a route in the [routes] table.
  ///
  /// If a route is requested that is not specified in this table (or by
  /// [home]), then the [onGeneratePage] callback is called to build the page
  /// instead.
  ///
  /// One of the [home], [pages], [onGeneratePage], or [onUnknownPage], must
  /// be provided.
  final Map<RegExp, PageBuilder>? _regexPages;


  /// The widget for the default page of the app ([Navigator.defaultRouteName],
  /// which is `/`).
  ///
  /// This is the page that is displayed first when the application is started
  /// normally, unless [RouteInformationProvider] is specified. It's also the
  /// route that's displayed if the [RouteInformationProvider] can't be displayed.
  ///
  /// To be able to directly call [Theme.of], [MediaQuery.of], etc, in the code
  /// that sets the [home] argument in the constructor, you can use a [Builder]
  /// widget to get a [BuildContext].
  ///
  /// If [home] is specified, then [pages] must not include an entry for `/`,
  /// as [home] takes its place.
  ///
  /// One of the [home], [pages], [onGeneratePage], or [onUnknownPage], must
  /// be provided.
  final Page? home;

  /// The route generator callback used when the app is navigated to a
  /// named route.
  ///
  /// If this returns null when building the routes to handle the specified
  /// [initialRoute], then all the routes are discarded and
  /// [Navigator.defaultRouteName] is used instead (`/`).
  ///
  /// During normal app operation, the [onGeneratePage] callback will only be
  /// applied to route names pushed by the application, and so should never
  /// return null.
  ///
  /// This is used if [routes] does not contain the requested route.
  ///
  /// The [Navigator] is only built if routes are provided (either via [home],
  /// [routes], [onGenerateRoute], or [onUnknownRoute]); if they are not,
  /// [builder] must not be null.
  final PageFactory? onGeneratePage;

  /// Called when [onGenerateRoute] fails to generate a route, except for the
  /// [initialRoute].
  ///
  /// This callback is typically used for error handling. For example, this
  /// callback might always generate a "not found" page that describes the route
  /// that wasn't found.
  ///
  /// Unknown routes can arise either from errors in the app or from external
  /// requests to push routes, such as from Android intents.
  ///
  /// The [Navigator] is only built if routes are provided (either via [home],
  /// [routes], [onGenerateRoute], or [onUnknownRoute]); if they are not,
  /// [builder] must not be null.
  final PageFactory? onUnknownPage;

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  List<_UriAndPage> get pageStack => _pageStack;
  List<_UriAndPage> _pageStack = const <_UriAndPage>[];
  set pageStack (List<_UriAndPage> other) {
    if (_pageStack != other) {
      _pageStack = other;
      notifyListeners();
    }
  }

  static Map<RegExp, PageBuilder> _convertsToRegexpMap(Map<String, PageBuilder> pages) {
    Map<RegExp, PageBuilder> regexpMap = <RegExp, PageBuilder>{};
    final RegExp routeParameterMatcher = RegExp(':(?<$pagesRegexGroupName>[^/]+)');
    for (String path in pages.keys) {
      String pattern = path;
      RegExpMatch? match = routeParameterMatcher.firstMatch(pattern);
      while(match != null) {
        final String name = match.namedGroup(pagesRegexGroupName)!;
        pattern = pattern.replaceFirst(':$name', '(?<$name>[^/]+)');
        // Finds next match.
        match = routeParameterMatcher.firstMatch(pattern);
      }
      regexpMap[RegExp('^$pattern(?:/|\$)')] = pages[path]!;
    }
    return regexpMap;
  }

  @override
  Uri? get currentConfiguration {
    print('current configuration is called ${_pageStack.isEmpty ? null : _pageStack.last.uri}');
    return _pageStack.isEmpty ? null : _pageStack.last.uri;
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) {
    _pageStack = _generatePages(configuration);
    notifyListeners();
    return SynchronousFuture<void>(null);
  }

  _UriAndPage? _generatePage(Uri uri) {
    if (_regexPages == null) {
      return null;
    }
    for (final RegExp pattern in _regexPages!.keys) {
      final RegExpMatch? match = pattern.firstMatch(uri.path);
      if (match != null) {
        final Map<String, String> pathParameters = <String, String> {};
        for (String groupName in match.groupNames) {
          pathParameters[groupName] = match.namedGroup(groupName)!;
        }
        return _UriAndPage(uri, _regexPages![pattern]!(uri, pathParameters));
      }
    }

    final Page<dynamic>? page = onGeneratePage != null
     ? onGeneratePage!(uri)
     : onUnknownPage != null
       ? onUnknownPage!(uri)
       : null;
    return page == null ? null : _UriAndPage(uri, page);

  }

  List<_UriAndPage> _generatePages(Uri configuration) {
    if (configuration.path == Navigator.defaultRouteName && home != null) {
      return <_UriAndPage>[_UriAndPage(configuration, home!)];
    }
    List<_UriAndPage> results = <_UriAndPage>[];
    final Uri prefixUri = Uri.parse('/');
    _UriAndPage? page = home == null ? _generatePage(prefixUri) : _UriAndPage(prefixUri, home!);
    if (page != null) {
      results.add(page);
    }
    String prefixPath = '';
    for (final String segment in configuration.pathSegments) {
      prefixPath += '/$segment';
      page = _generatePage(Uri.parse(prefixPath));
      if (page != null) {
        results.add(page);
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return _PageBasedNavigator(
      key: navigatorKey,
      onPopPage: (Route<dynamic> route, dynamic result) {
        final bool success = route.didPop(result);
        if (success) {
          _pageStack.removeLast();
        }
        return success;
      },
      pages: _pageStack.map<Page<dynamic>>((_UriAndPage wrapper) => wrapper.page).toList(),
    );
  }
}

class _UriAndPage {
  const _UriAndPage(this.uri, this.page);
  final Uri uri;
  final Page<void> page;
}

class _PageBasedNavigator extends Navigator {
  const _PageBasedNavigator({
    required Key key,
    required PopPageCallback onPopPage,
    required List<Page<dynamic>> pages
  }) : super(key: key, onPopPage: onPopPage, pages: pages);

  @override
  NavigatorState createState() => _PageBasedNavigatorState();
}

class _PageBasedNavigatorState extends NavigatorState {
  @override
  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final SimpleRouterDelegate delegate = Router.of(context).routerDelegate as SimpleRouterDelegate;
    delegate.setNewRoutePath(Uri.parse(routeName));
    return Future<T>.value(null);
  }


}