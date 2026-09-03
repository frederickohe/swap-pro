import 'package:flutter/services.dart';
import 'package:swappro/barrel.dart';
import 'package:swappro/features/initial_ui/server_error_page.dart';
import 'package:swappro/services/connectivity_notifier.dart';

// Initialize services at app level
late TokenService _tokenService;
late SessionAwareHttpClient _httpClient;
late ApiService _apiService;
late AuthBloc _authBloc;

void _onConnectivityChanged() {
  if (!appConnectivityNotifier.isServerUnreachable) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = NavigationService.navigatorKey.currentState;
    if (nav == null) return;

    final currentRoute = ModalRoute.of(nav.context)?.settings.name;
    if (currentRoute == 'ServerErrorPage') return;

    // Only interrupt cold start / splash — not an active in-app session.
    final authState = _authBloc.state;
    if (authState is Authenticated || authState is TokenRefreshed) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ServerErrorPage'),
        builder: (_) => ServerErrorPage(
          onRetry: () async {
            _authBloc.add(const CheckSessionEvent());
          },
        ),
      ),
      (route) => false,
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  print('=== APP STARTING ===');

  await AppConfig.init();
  print('✓ AppConfig initialized');

  appConnectivityNotifier.addListener(_onConnectivityChanged);

  _tokenService = TokenService();
  _httpClient = SessionAwareHttpClient(
    tokenService: _tokenService,
    baseUrl: AppConfig.backendUrl,
    connectivityNotifier: appConnectivityNotifier,
  );
  _apiService = ApiService(httpClient: _httpClient);
  print('✓ Services initialized');

  final successBloc = SuccessBloc();
  _authBloc = AuthBloc(
    tokenService: _tokenService,
    successBloc: successBloc,
  );
  _httpClient.onSessionExpired = () {
    _authBloc.add(const SessionExpiredEvent());
  };
  print('✓ BLoCs created');

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(create: (context) => _apiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: successBloc),
          BlocProvider(create: (context) => ThemeBloc()),
          BlocProvider(
            create: (context) =>
                SwapRequestCubit(apiService: context.read<ApiService>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
  print('=== APP INITIALIZED ===');
}

SessionAwareHttpClient get appHttpClient => _httpClient;
ApiService get apiService => _apiService;
TokenService get tokenService => _tokenService;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final authState = _authBloc.state;
    if (authState is! Authenticated && authState is! TokenRefreshed) return;

    _authBloc.add(const CheckSessionEvent());
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is! SessionExpired) return;

    context.showAppSnackBar(state.message);

    final nav = NavigationService.navigatorKey.currentState;
    if (nav == null) return;

    // Keep browsing available; prompt login via the auth sheet (web parity).
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeEntry(),
      ),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let HomeEntry finish replacing itself with Home.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final sheetContext = NavigationService.navigatorKey.currentContext;
      if (sheetContext == null || !sheetContext.mounted) return;
      if (isAuthenticated(sheetContext)) return;
      await ensureAuthenticated(sheetContext, sessionExpired: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthStateChanged,
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
            navigatorObservers: [NavigationService.keyboardDismissObserver],
            debugShowCheckedModeBanner: false,
            title: 'Swap Pro',
            theme: state.themeData,
            home: const SplashWrapper(),
          );
        },
      ),
    );
  }
}
