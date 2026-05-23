import 'package:swappro/barrel.dart';

// Initialize services at app level
late TokenService _tokenService;
late SessionAwareHttpClient _httpClient;
late ApiService _apiService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== APP STARTING ===');

  // Initialize environment variables
  await AppConfig.init();
  print('✓ AppConfig initialized');

  // Initialize session handling services
  _tokenService = TokenService();
  _httpClient = SessionAwareHttpClient(
    tokenService: _tokenService,
    baseUrl: AppConfig.backendUrl,
  );
  _apiService = ApiService(httpClient: _httpClient);
  print('✓ Services initialized');

  // Create blocs
  final successBloc = SuccessBloc();
  final authBloc = AuthBloc(
    tokenService: _tokenService,
    successBloc: successBloc,
  );
  print('✓ BLoCs created');

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(create: (context) => _apiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: successBloc),
          BlocProvider(create: (context) => ThemeBloc()),
        ],
        child: MyApp(httpClient: _httpClient),
      ),
    ),
  );
  print('=== APP INITIALIZED ===');
}

//Getters
SessionAwareHttpClient get appHttpClient => _httpClient;
ApiService get apiService => _apiService;
TokenService get tokenService => _tokenService;

class MyApp extends StatelessWidget {
  final SessionAwareHttpClient httpClient;

  const MyApp({required this.httpClient, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Swap Pro',
          theme: state.themeData,
          home: const SplashWrapper(),
        );
      },
    );
  }
}
