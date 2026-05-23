import 'package:swappro/barrel.dart';
import 'dart:developer';
import 'package:swappro/features/notifications/models/app_notification.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final SessionAwareHttpClient httpClient;
  final String baseUrl;

  /// Same folder the backend uses for RAG uploads (`chatbot-files`).
  static const String chatbotStorageFolder = 'chatbot-files';

  /// Catalogue files for product management (`StorageFolder.records_files`).
  static const String productCatalogStorageFolder = 'records-files';

  /// Product listing images (`StorageFolder.product_images` on the API).
  static const String productImageStorageFolder = 'product-images';

  ApiService({required this.httpClient, String? baseUrl})
    : baseUrl = baseUrl?.isNotEmpty == true
          ? baseUrl!
          : '${AppConfig.backendUrl}/api/v1';

  /// Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await httpClient.get(Uri.parse('$baseUrl/user/me'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  /// Get all rides/buses
  Future<List<dynamic>> getRides() async {
    try {
      debugPrint('Fetching rides from: $baseUrl/rides');
      final response = await httpClient.get(Uri.parse('$baseUrl/rides'));

      debugPrint('Rides response status: ${response.statusCode}');
      debugPrint('Rides response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Decoded data type: ${data.runtimeType}');

        if (data is Map && data.containsKey('rides')) {
          debugPrint('Found rides in response: ${data['rides'].length} rides');
          return data['rides'];
        }
        debugPrint('Data is not a map or does not contain rides key');
        return data is List ? data : [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expired - unauthorized');
      } else {
        throw Exception(
          'Failed to fetch rides: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching rides: $e');
      throw Exception('Error fetching rides: $e');
    }
  }

  /// Get ride details by ID
  Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/rides/$rideId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 404) {
        throw Exception('Ride not found');
      } else {
        throw Exception('Failed to fetch ride details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ride details: $e');
    }
  }

  /// Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String rideId,
    required int seats,
    required String pickupLocation,
    required String dropoffLocation,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ride_id': rideId,
          'seats': seats,
          'pickup_location': pickupLocation,
          'dropoff_location': dropoffLocation,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Invalid booking details');
      } else {
        throw Exception('Failed to create booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  /// Get user bookings
  Future<List<dynamic>> getUserBookings() async {
    try {
      final response = await httpClient.get(Uri.parse('$baseUrl/bookings'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('bookings')) {
          return data['bookings'];
        }
        return data is List ? data : [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  /// Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 404) {
        throw Exception('Booking not found');
      } else {
        throw Exception('Failed to cancel booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error canceling booking: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? fullname,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? nationality,
    DateTime? dateOfBirth,
    String? gender,
    String? staffId,
    String? ghanaCard,
    // Notifications preferences
    bool? inAppNotifications,
    bool? smsNotifications,
    // Business / membership
    String? company,
    String? currentBranch,
    String? address,
    String? location,
    // Socials
    String? facebookUrl,
    String? whatsappNumber,
    String? linkedinUrl,
    String? twitterUrl,
    String? instagramUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullname != null) body['fullname'] = fullname;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (profilePictureUrl != null) {
        body['profile_picture_url'] = profilePictureUrl;
      }
      if (nationality != null) body['nationality'] = nationality;
      if (dateOfBirth != null) {
        body['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
      }
      if (gender != null) body['gender'] = gender;
      if (staffId != null) body['staff_id'] = staffId;
      if (ghanaCard != null) body['ghana_card'] = ghanaCard;

      if (inAppNotifications != null) {
        body['in_app_notifications'] = inAppNotifications;
      }
      if (smsNotifications != null)
        body['sms_notifications'] = smsNotifications;

      if (company != null) body['company'] = company;
      if (currentBranch != null) body['current_branch'] = currentBranch;
      if (address != null) body['address'] = address;
      if (location != null) body['location'] = location;

      if (facebookUrl != null) body['facebook_url'] = facebookUrl;
      if (whatsappNumber != null) body['whatsapp_number'] = whatsappNumber;
      if (linkedinUrl != null) body['linkedin_url'] = linkedinUrl;
      if (twitterUrl != null) body['twitter_url'] = twitterUrl;
      if (instagramUrl != null) body['instagram_url'] = instagramUrl;

      final response = await httpClient.put(
        Uri.parse('$baseUrl/user/me'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Invalid profile data');
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Patch current user's notification settings.
  ///
  /// Backend: `PATCH /api/v1/user/me/notification-settings`
  /// Body: `{ "in_app_notification": true, "sms_notification": true }`
  Future<Map<String, dynamic>> patchMyNotificationSettings({
    bool? inAppNotification,
    bool? smsNotification,
  }) async {
    final body = <String, dynamic>{};
    if (inAppNotification != null) {
      body['in_app_notification'] = inAppNotification;
    }
    if (smsNotification != null) body['sms_notification'] = smsNotification;

    final response = await httpClient.patch(
      Uri.parse('$baseUrl/user/me/notification-settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to update notification settings: ${response.statusCode} ${response.body}',
    );
  }

  /// Patch a specific user's notification settings by id.
  ///
  /// Backend: `PATCH /api/v1/user/{user_id}/notification-settings`
  Future<Map<String, dynamic>> patchUserNotificationSettings({
    required String userId,
    bool? inAppNotification,
    bool? smsNotification,
  }) async {
    final body = <String, dynamic>{};
    if (inAppNotification != null) {
      body['in_app_notification'] = inAppNotification;
    }
    if (smsNotification != null) body['sms_notification'] = smsNotification;

    final response = await httpClient.patch(
      Uri.parse('$baseUrl/user/$userId/notification-settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to update notification settings: ${response.statusCode} ${response.body}',
    );
  }

  /// Patch current user's profile image URL only.
  ///
  /// Backend: `PATCH /api/v1/user/me/profile-image`
  /// Body: `{ "profile_picture_url": "https://..." }`
  Future<Map<String, dynamic>> patchMyProfileImage({
    required String profilePictureUrl,
  }) async {
    final response = await httpClient.patch(
      Uri.parse('$baseUrl/user/me/profile-image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'profile_picture_url': profilePictureUrl}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to update profile image: ${response.statusCode} ${response.body}',
    );
  }

  /// Patch a specific user's profile image URL by id.
  ///
  /// Backend: `PATCH /api/v1/user/{user_id}/profile-image`
  Future<Map<String, dynamic>> patchUserProfileImage({
    required String userId,
    required String profilePictureUrl,
  }) async {
    final response = await httpClient.patch(
      Uri.parse('$baseUrl/user/$userId/profile-image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'profile_picture_url': profilePictureUrl}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to update profile image: ${response.statusCode} ${response.body}',
    );
  }

  /// Upload a file (image/doc) to storage service.
  ///
  /// Backend: `POST /api/v1/storage/upload` (form-data: `file`)
  /// Returns: `{ file_name, file_url }`
  Future<String> uploadFile({
    required File file,
    String? filename,
    String fieldName = 'file',
    String? storageFolder,
  }) async {
    var uri = Uri.parse('$baseUrl/storage/upload');
    final folder = storageFolder?.trim();
    if (folder != null && folder.isNotEmpty) {
      uri = uri.replace(queryParameters: {'folder': folder});
    }
    final request = http.MultipartRequest('POST', uri);

    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      filename: filename,
    );
    request.files.add(multipartFile);

    final streamed = await httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final url = (data['file_url'] ?? data['url'] ?? '').toString();
      if (url.isEmpty) {
        throw Exception('Upload succeeded but no file_url returned');
      }
      return url;
    }

    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }

  /// Same as [uploadFile] but from bytes (e.g. web `FilePicker` with `withData: true`).
  Future<String> uploadFileBytes({
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    String? storageFolder,
  }) async {
    var uri = Uri.parse('$baseUrl/storage/upload');
    final folder = storageFolder?.trim();
    if (folder != null && folder.isNotEmpty) {
      uri = uri.replace(queryParameters: {'folder': folder});
    }
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
    );

    final streamed = await httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final url = (data['file_url'] ?? data['url'] ?? '').toString();
      if (url.isEmpty) {
        throw Exception('Upload succeeded but no file_url returned');
      }
      return url;
    }

    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }

  /// List available files in storage (typically AI training docs).
  ///
  /// Backend: `GET /api/v1/storage/list?subfolder=chatbot-files/&extensions=txt,pdf,docx`
  /// Returns: `{ "files": [ { file_name, file_url, file_size, file_type, last_modified } ] }`
  Future<List<Map<String, dynamic>>> listStorageFiles({
    String subfolder = 'chatbot-files/',
    List<String> extensions = const ['txt', 'pdf', 'docx'],
    int maxKeys = 200,
  }) async {
    final uri = Uri.parse('$baseUrl/storage/list').replace(
      queryParameters: {
        'subfolder': subfolder,
        'extensions': extensions.join(','),
        'max_keys': maxKeys.toString(),
      },
    );

    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final files =
          (decoded is Map ? (decoded['files'] ?? decoded['data']) : decoded) ??
          const [];
      if (files is List) {
        return files
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to list storage files: ${response.statusCode} ${response.body}',
    );
  }

  /// List files for the authenticated user under:
  /// `operations/<folder>/<jwtSubject>/`
  ///
  /// Backend: `GET /api/v1/storage/me/files?folder=<folder>`
  /// Returns: `List[FileDTO]` (each includes a presigned URL)
  Future<List<Map<String, dynamic>>> listMyStorageFiles({
    required String folder,
  }) async {
    final normalizedFolder = folder.trim().replaceAll('\\', '/');
    final uri = Uri.parse(
      '$baseUrl/storage/me/files',
    ).replace(queryParameters: {'folder': normalizedFolder});

    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data =
          (decoded is Map ? (decoded['files'] ?? decoded['data']) : decoded) ??
          const [];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to list my storage files: ${response.statusCode} ${response.body}',
    );
  }

  /// Download a user's file.
  ///
  /// Backend: `GET /api/v1/storage/me/download/{file_name}?folder=<folder>`
  /// Note: This may return bytes or a redirect depending on backend.
  Uri myStorageDownloadUri({required String folder, required String fileName}) {
    final normalizedFolder = folder.trim().replaceAll('\\', '/');
    return Uri.parse(
      '$baseUrl/storage/me/download/${Uri.encodeComponent(fileName)}',
    ).replace(queryParameters: {'folder': normalizedFolder});
  }

  /// Delete a user's file.
  ///
  /// Backend: `DELETE /api/v1/storage/me/file/{file_name}?folder=<folder>`
  Future<void> deleteMyStorageFile({
    required String folder,
    required String fileName,
  }) async {
    final normalizedFolder = folder.trim().replaceAll('\\', '/');
    final uri = Uri.parse(
      '$baseUrl/storage/me/file/${Uri.encodeComponent(fileName)}',
    ).replace(queryParameters: {'folder': normalizedFolder});

    final response = await httpClient.delete(uri);
    if (response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204) {
      return;
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to delete file: ${response.statusCode} ${response.body}',
    );
  }

  /// Upload a file to the authenticated user's folder.
  ///
  /// Backend: `POST /api/v1/storage/me/upload-multiple?folder=<folder>`
  /// Form-data: `files` (one or more)
  /// Returns: `List[FileDTO]` (each includes a presigned URL)
  Future<Map<String, dynamic>> uploadMyStorageFile({
    required String folder,
    required File file,
    String fieldName = 'files',
    String? filename,
  }) async {
    final normalizedFolder = folder.trim().replaceAll('\\', '/');
    final uri = Uri.parse(
      '$baseUrl/storage/me/upload-multiple',
    ).replace(queryParameters: {'folder': normalizedFolder});

    final request = http.MultipartRequest('POST', uri);
    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      filename: filename,
    );
    request.files.add(multipartFile);

    final streamed = await httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Upload succeeded but response shape was unexpected');
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to upload file: ${response.statusCode} ${response.body}',
    );
  }

  /// Upload one document for RAG indexing (storage + optional Qdrant).
  ///
  /// Backend: `POST /api/v1/storage/me/upload-rag-document?folder=<folder>`
  /// Multipart field name: `file` (single).
  ///
  /// When [asyncMode] is true, returns immediately with a `job_id` (HTTP 202);
  /// poll [getRagIndexJobStatus] for progress.
  Future<Map<String, dynamic>> uploadRagDocument({
    String folder = chatbotStorageFolder,
    required String filename,
    String? filePath,
    List<int>? fileBytes,
    bool asyncMode = false,
  }) async {
    final trimmedPath = filePath?.trim();
    final hasPath = trimmedPath != null && trimmedPath.isNotEmpty;
    final hasBytes = fileBytes != null && fileBytes.isNotEmpty;
    if (!hasPath && !hasBytes) {
      throw ArgumentError('Provide filePath or non-empty fileBytes');
    }
    if (hasPath && hasBytes) {
      throw ArgumentError('Provide only one of filePath or fileBytes');
    }

    final normalizedFolder = folder.trim().replaceAll('\\', '/');
    final uri = Uri.parse('$baseUrl/storage/me/upload-rag-document').replace(
      queryParameters: {
        'folder': normalizedFolder,
        if (asyncMode) 'async_mode': 'true',
      },
    );

    final request = http.MultipartRequest('POST', uri);
    final http.MultipartFile multipartFile =
        trimmedPath != null && trimmedPath.isNotEmpty
        ? await http.MultipartFile.fromPath(
            'file',
            trimmedPath,
            filename: filename,
          )
        : http.MultipartFile.fromBytes('file', fileBytes!, filename: filename);
    request.files.add(multipartFile);

    final streamed = await httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        (asyncMode && response.statusCode == 202)) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('Upload succeeded but response shape was unexpected');
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to upload RAG document: ${response.statusCode} ${response.body}',
    );
  }

  /// Scrape a public website and index its text into RAG.
  ///
  /// Backend: `POST /api/v1/storage/me/upload-rag-url?folder=<folder>`
  /// Returns immediately with a `job_id`; poll [getRagIndexJobStatus].
  Future<Map<String, dynamic>> uploadRagUrl({
    required String url,
    String folder = chatbotStorageFolder,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('url must not be empty');
    }

    final normalizedFolder = folder.trim().replaceAll('\\', '/');
    final uri = Uri.parse(
      '$baseUrl/storage/me/upload-rag-url',
    ).replace(queryParameters: {'folder': normalizedFolder});

    final response = await httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': trimmed}),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 202) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('URL index started but response shape was unexpected');
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to index website: ${response.statusCode} ${response.body}',
    );
  }

  /// Poll indexing progress for an async file or URL upload.
  ///
  /// Backend: `GET /api/v1/storage/me/rag-index-jobs/{job_id}`
  Future<Map<String, dynamic>> getRagIndexJobStatus(String jobId) async {
    final trimmed = jobId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('jobId must not be empty');
    }

    final uri = Uri.parse(
      '$baseUrl/storage/me/rag-index-jobs/${Uri.encodeComponent(trimmed)}',
    );
    final response = await httpClient.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('Unexpected job status response shape');
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode == 404) {
      throw Exception('Indexing job not found');
    }
    throw Exception(
      'Failed to get RAG job status: ${response.statusCode} ${response.body}',
    );
  }

  static String? ragIndexJobId(Map<String, dynamic> startResponse) {
    final id = startResponse['job_id'];
    if (id == null) return null;
    final s = id.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool ragIndexJobTerminal(Map<String, dynamic> status) {
    final s = (status['status'] ?? '').toString().toLowerCase();
    return s == 'completed' || s == 'failed';
  }

  static bool ragIndexJobSucceeded(Map<String, dynamic> status) {
    return (status['status'] ?? '').toString().toLowerCase() == 'completed';
  }

  /// Get available rides with filters
  Future<List<dynamic>> searchRides({
    required String departure,
    required String destination,
    required DateTime date,
  }) async {
    try {
      final response = await httpClient.get(
        Uri.parse(
          '$baseUrl/rides/search?departure=$departure&destination=$destination&date=${date.toIso8601String().split('T')[0]}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('rides')) {
          return data['rides'];
        }
        return data is List ? data : [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to search rides: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching rides: $e');
    }
  }

  /// Get total revenue
  Future<double> getTotalRevenue() async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/payment/revenue'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as num).toDouble();
    }
    return 0.0;
  }

  /// GET /api/v1/payment/revenue/{timeline} — revenue for TODAY, THIS_WEEK, etc.
  Future<double> getRevenueByTimeline(String timeline) async {
    final key = timeline.trim().toUpperCase();
    if (key.isEmpty || key == 'ALL') return getTotalRevenue();
    final response = await httpClient.get(
      Uri.parse('$baseUrl/payment/revenue/$key'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as num).toDouble();
    }
    return 0.0;
  }

  /// GET /api/v1/products/inventory/low-stock
  Future<List<Map<String, dynamic>>> getLowStockInventory({
    double threshold = 0.5,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/products/inventory/low-stock',
    ).replace(queryParameters: {'threshold': '$threshold'});
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! List) return [];
      return data
          .map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          })
          .where((m) => m.isNotEmpty)
          .toList();
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    return [];
  }

  /// GET /api/v1/interventions/list
  Future<List<Map<String, dynamic>>> listInterventions({
    String? status,
    int limit = 50,
  }) async {
    final qp = <String, String>{'limit': '$limit'};
    final trimmedStatus = status?.trim();
    if (trimmedStatus != null && trimmedStatus.isNotEmpty) {
      qp['status'] = trimmedStatus;
    }
    final uri = Uri.parse(
      '$baseUrl/interventions/list',
    ).replace(queryParameters: qp);
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map) {
        return _decodeMapList(data['items']);
      }
      if (data is List) return _decodeMapList(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    return [];
  }

  /// Get financial transaction history
  Future<List<Map<String, dynamic>>> getFinancials({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/user/me/financials?page=$page&page_size=$pageSize'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Get connected social media accounts
  Future<List<Map<String, dynamic>>> getSocialAccounts() async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/social/accounts'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accounts = data['accounts'] as List? ?? [];
      return List<Map<String, dynamic>>.from(accounts);
    }
    return [];
  }

  /// Publish a post to connected social accounts
  Future<Map<String, dynamic>> publishSocialPost({
    required List<String> accountIds,
    required String content,
    List<String> mediaUrls = const [],
    String? scheduleTime,
    List<String> hashtags = const [],
  }) async {
    final body = <String, dynamic>{
      'account_ids': accountIds,
      'content': content,
      if (mediaUrls.isNotEmpty)
        'media_urls': mediaUrls
            .map((u) => {'url': u, 'type': 'image'})
            .toList(),
      if (scheduleTime != null) 'schedule_time': scheduleTime,
      if (hashtags.isNotEmpty) 'hashtags': hashtags,
    };

    final response = await httpClient.post(
      Uri.parse('$baseUrl/social/post'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to publish: ${response.statusCode} ${response.body}',
    );
  }

  Future<String> generateAgentContent({
    required String userId,
    required String prompt,
    String agentName = 'marketing',
  }) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/agent/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userid': userId,
        'message': prompt,
        'agent_name': agentName,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['response'] ?? data['message'] ?? data['reply'] ?? '')
          .toString();
    }
    throw Exception('Agent error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> generateImageMedia({
    required String prompt,
    String? userId,
    Duration timeout = const Duration(minutes: 11),
  }) async {
    final response = await httpClient
        .post(
          Uri.parse('$baseUrl/media/generate-image'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': prompt,
            if (userId != null && userId.trim().isNotEmpty) 'user_id': userId,
          }),
        )
        .timeout(
          timeout,
          onTimeout: () => throw Exception(
            'Image generation timed out. The server may still be processing; try again.',
          ),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('Image generation returned an unexpected response');
    }

    throw Exception(
      'Image generation failed: ${response.statusCode} ${response.body}',
    );
  }

  /// [store] When true, the backend downloads the Veo output and uploads a public MP4 URL
  /// (recommended for in-app playback; raw Google URLs often fail on Android ExoPlayer).
  Future<Map<String, dynamic>> generateVideoMedia({
    required String prompt,
    String? userId,
    bool store = false,
    Duration timeout = const Duration(minutes: 11),
  }) async {
    final uri = Uri.parse(
      '$baseUrl/media/generate-video',
    ).replace(queryParameters: {'store': store.toString()});
    final response = await httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt': prompt,
            if (userId != null && userId.trim().isNotEmpty) 'user_id': userId,
          }),
        )
        .timeout(
          timeout,
          onTimeout: () => throw Exception(
            'Video generation timed out. The server may still be processing; try again.',
          ),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('Video generation returned an unexpected response');
    }

    throw Exception(
      'Video generation failed: ${response.statusCode} ${response.body}',
    );
  }

  /// GET /api/v1/user/me/notifications — paged list for the current user.
  /// Also accepts the legacy shape from GET /api/v1/notification/.
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int size = 100,
    String? status,
  }) async {
    final queryParameters = <String, String>{'page': '$page', 'size': '$size'};
    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }
    final uri = Uri.parse(
      '$baseUrl/user/me/notifications',
    ).replace(queryParameters: queryParameters);
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List
          ? data
          : (data is Map
                ? (data['notifications'] ??
                      data['data'] ??
                      data['items'] ??
                      data['results'] ??
                      [])
                : []);
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to fetch notifications: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<AppNotification>> getUnreadNotifications({
    int page = 1,
    int size = 100,
  }) async {
    final items = await getNotifications(
      page: page,
      size: size,
      status: 'UNREAD',
    );
    return items.where((n) => !n.read).toList();
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final items = await getUnreadNotifications();
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  /// PATCH /api/v1/notification/{id}/read
  Future<AppNotification> markNotificationAsRead(String notificationId) async {
    final response = await httpClient.patch(
      Uri.parse('$baseUrl/notification/$notificationId/read'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AppNotification.fromJson(data);
      }
      if (data is Map) {
        return AppNotification.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Invalid mark-as-read response');
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      'Failed to mark notification as read: ${response.statusCode} ${response.body}',
    );
  }

  /// GET /api/v1/social/connect/{platform} — OAuth authorization URL for a platform.
  Future<PlatformEmbedSession> initiateSocialConnect(String platform) async {
    final slug = platform.trim().toLowerCase();
    final response = await httpClient.get(
      Uri.parse('$baseUrl/social/connect/$slug'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final authUrl = (data['authorization_url'] ?? data['auth_url'] ?? '')
            .toString();
        if (authUrl.isNotEmpty) {
          return PlatformEmbedSession(authorizationUrl: authUrl);
        }
        throw Exception('Unsupported social connect response for $slug');
      }
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final authUrl = (map['authorization_url'] ?? map['auth_url'] ?? '')
            .toString();
        if (authUrl.isNotEmpty) {
          return PlatformEmbedSession(authorizationUrl: authUrl);
        }
      }
      throw Exception('Invalid social connect response');
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Could not start $slug connection (${response.statusCode})',
    );
  }

  /// GET /api/v1/orders/me — current user's orders; optional [orderStatus] filter.
  Future<List<Map<String, dynamic>>> listOrders({
    int skip = 0,
    int limit = 100,
    String? orderStatus,
  }) async {
    final qp = <String, String>{'skip': '$skip', 'limit': '$limit'};
    final trimmedStatus = orderStatus?.trim();
    if (trimmedStatus != null && trimmedStatus.isNotEmpty) {
      qp['order_status'] = trimmedStatus;
    }
    final uri = Uri.parse('$baseUrl/orders/me').replace(queryParameters: qp);
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! List) return [];
      return data
          .map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          })
          .where((m) => m.isNotEmpty)
          .toList();
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load orders (${response.statusCode})',
    );
  }

  /// GET /api/v1/products/me — current user's products; optional [category] filter.
  Future<List<Map<String, dynamic>>> listProducts({
    int skip = 0,
    int limit = 100,
    String? category,
  }) async {
    final qp = <String, String>{'skip': '$skip', 'limit': '$limit'};
    final trimmedCategory = category?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      qp['category'] = trimmedCategory;
    }
    final uri = Uri.parse('$baseUrl/products/me').replace(queryParameters: qp);
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! List) return [];
      return data
          .map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          })
          .where((m) => m.isNotEmpty)
          .toList();
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load products (${response.statusCode})',
    );
  }

  /// GET /api/v1/products/{productId}
  Future<Map<String, dynamic>> getProduct(String productId) async {
    final uri = Uri.parse(
      '$baseUrl/products/${Uri.encodeComponent(productId)}',
    );
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode == 404) {
      throw Exception('Product not found');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load product (${response.statusCode})',
    );
  }

  /// POST /api/v1/products — create a product (inventory is created on the server).
  ///
  /// [photos] must contain at least one image URL (see backend `ProductCreateDTO`).
  Future<Map<String, dynamic>> createProduct({
    required String name,
    String? description,
    required double price,
    String? category,
    required String condition,
    int? numberInStock,
    String? link,
    required List<String> photos,
  }) async {
    final urls = photos
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (urls.isEmpty) {
      throw ArgumentError('At least one product image URL is required');
    }

    final body = <String, dynamic>{
      'name': name.trim(),
      'price': price,
      'condition': condition.trim(),
      'photos': urls,
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }
    if (numberInStock != null) body['number_in_stock'] = numberInStock;
    if (link != null && link.trim().isNotEmpty) body['link'] = link.trim();

    final uri = Uri.parse('$baseUrl/products');
    final response = await httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to create product (${response.statusCode})',
    );
  }

  /// PUT /api/v1/products/{productId}
  Future<Map<String, dynamic>> updateProduct(
    String productId, {
    String? name,
    String? description,
    double? price,
    String? category,
    String? condition,
    int? numberInStock,
    String? photo,
    String? link,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (description != null) body['description'] = description.trim();
    if (price != null) body['price'] = price;
    if (category != null) body['category'] = category.trim();
    if (condition != null && condition.trim().isNotEmpty) {
      body['condition'] = condition.trim();
    }
    if (numberInStock != null) body['number_in_stock'] = numberInStock;
    if (photo != null && photo.trim().isNotEmpty) body['photo'] = photo.trim();
    if (link != null) body['link'] = link.trim();

    final uri = Uri.parse(
      '$baseUrl/products/${Uri.encodeComponent(productId)}',
    );
    final response = await httpClient.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to update product (${response.statusCode})',
    );
  }

  /// DELETE /api/v1/products/{productId}
  Future<void> deleteProduct(String productId) async {
    final uri = Uri.parse(
      '$baseUrl/products/${Uri.encodeComponent(productId)}',
    );
    final response = await httpClient.delete(uri);
    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode == 404) {
      throw Exception('Product not found');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to delete product (${response.statusCode})',
    );
  }

  /// GET /api/v1/conversations/session/{sessionId} — full session with history.
  Future<Map<String, dynamic>> getConversationSession(int sessionId) async {
    final uri = Uri.parse('$baseUrl/conversations/session/$sessionId');
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode == 404) {
      throw Exception('Conversation not found');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load conversation (${response.statusCode})',
    );
  }

  /// GET /api/v1/conversations/for-order/{orderId} — customer chat for an order.
  Future<Map<String, dynamic>> getConversationForOrder(String orderId) async {
    final uri = Uri.parse(
      '$baseUrl/conversations/for-order/${Uri.encodeComponent(orderId)}',
    );
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode == 404) {
      throw Exception('No conversation found for this order');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load order conversation (${response.statusCode})',
    );
  }

  /// POST /api/v1/interventions/human-message — agent reply during intervention.
  Future<Map<String, dynamic>> sendInterventionHumanMessage(
    String message, {
    int? sessionId,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty');
    }
    final qp = <String, String>{'message': trimmed};
    if (sessionId != null) {
      qp['session_id'] = '$sessionId';
    }
    final uri = Uri.parse(
      '$baseUrl/interventions/human-message',
    ).replace(queryParameters: qp);
    final response = await httpClient.post(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final conv = data is Map ? data['conversation'] : null;
      if (conv is Map<String, dynamic>) return conv;
      if (conv is Map) return Map<String, dynamic>.from(conv);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'success': true};
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to send message (${response.statusCode})',
    );
  }

  /// POST /api/v1/conversations/session/{sessionId}/deactivate-intervention
  Future<Map<String, dynamic>> deactivateConversationIntervention(
    int sessionId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/conversations/session/$sessionId/deactivate-intervention',
    );
    final response = await httpClient.post(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final conv = data is Map ? data['conversation'] : null;
      if (conv is Map<String, dynamic>) return conv;
      if (conv is Map) return Map<String, dynamic>.from(conv);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to deactivate intervention (${response.statusCode})',
    );
  }

  /// GET /api/v1/orders/{orderId}
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final uri = Uri.parse('$baseUrl/orders/${Uri.encodeComponent(orderId)}');
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode == 404) {
      throw Exception('Order not found');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load order (${response.statusCode})',
    );
  }

  /// PUT /api/v1/orders/{orderId}
  Future<Map<String, dynamic>> updateOrder(
    String orderId, {
    String? orderStatus,
    String? paymentStatus,
    String? fulfillmentStatus,
  }) async {
    final body = <String, dynamic>{};
    if (orderStatus != null && orderStatus.trim().isNotEmpty) {
      body['order_status'] = orderStatus.trim();
    }
    if (paymentStatus != null && paymentStatus.trim().isNotEmpty) {
      body['payment_status'] = paymentStatus.trim();
    }
    if (fulfillmentStatus != null && fulfillmentStatus.trim().isNotEmpty) {
      body['fulfillment_status'] = fulfillmentStatus.trim();
    }
    final uri = Uri.parse('$baseUrl/orders/${Uri.encodeComponent(orderId)}');
    final response = await httpClient.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to update order (${response.statusCode})',
    );
  }

  /// POST /api/v1/orders/{orderId}/send-invoice — payment link + message to customer chat.
  Future<Map<String, dynamic>> sendOrderInvoice(
    String orderId, {
    String? customerEmail,
  }) async {
    final qp = <String, String>{};
    final trimmedEmail = customerEmail?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      qp['customer_email'] = trimmedEmail;
    }
    final uri = Uri.parse(
      '$baseUrl/orders/${Uri.encodeComponent(orderId)}/send-invoice',
    ).replace(queryParameters: qp.isEmpty ? null : qp);
    final response = await httpClient.post(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to send invoice (${response.statusCode})',
    );
  }

  /// GET /api/v1/conversations/me — `{ completed, intervention_active }`.
  /// `completed` lists sessions without active intervention (history / all chats).
  Future<Map<String, List<Map<String, dynamic>>>> listMyConversations({
    int skip = 0,
    int limit = 100,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/conversations/me',
    ).replace(queryParameters: {'skip': '$skip', 'limit': '$limit'});
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! Map) {
        return {'completed': [], 'intervention_active': []};
      }
      return {
        'completed': _decodeMapList(data['completed']),
        'intervention_active': _decodeMapList(data['intervention_active']),
      };
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load conversations (${response.statusCode})',
    );
  }

  List<Map<String, dynamic>> _decodeMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  /// GET /api/v1/user/me/emails/sent — body `{ emails: [...], total_returned }`.
  /// Server validates `limit` ≤ 50.
  Future<Map<String, dynamic>> getMySentEmails({int limit = 50}) async {
    final safeLimit = limit.clamp(1, 50);
    final uri = Uri.parse(
      '$baseUrl/user/me/emails/sent',
    ).replace(queryParameters: {'limit': '$safeLimit'});
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'emails': <dynamic>[], 'total_returned': 0};
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load sent emails (${response.statusCode})',
    );
  }

  /// Notifications where `sms_sent` is true (`GET /api/v1/user/me/notifications`).
  Future<List<Map<String, dynamic>>> getMySentSms({int size = 100}) async {
    final uri = Uri.parse(
      '$baseUrl/user/me/notifications',
    ).replace(queryParameters: {'page': '1', 'size': '${size.clamp(1, 100)}'});
    final response = await httpClient.get(uri);
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    if (response.statusCode != 200) {
      throw Exception(
        _httpDetailMessage(response.body) ??
            'Failed to load sent SMS (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body);
    final list = data is List
        ? data
        : (data is Map
              ? (data['notifications'] ??
                    data['data'] ??
                    data['items'] ??
                    data['results'] ??
                    [])
              : []);
    if (list is! List) return const [];

    final sent = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);
      if (!_jsonTruthy(raw['sms_sent'])) continue;

      final nested = raw['data'];
      final map = nested is Map
          ? Map<String, dynamic>.from(nested)
          : <String, dynamic>{};
      sent.add({
        'phone': (raw['sms_phone'] ?? map['phone'] ?? map['to'] ?? '')
            .toString(),
        'message':
            (map['message'] ??
                    map['body'] ??
                    map['content'] ??
                    map['description'] ??
                    '')
                .toString(),
        'sent_at': (raw['sms_sent_at'] ?? raw['created_at'] ?? '').toString(),
        'status': (raw['sms_status'] ?? raw['sms_delivery_status'] ?? '')
            .toString(),
      });
    }
    return sent;
  }

  static bool _jsonTruthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  /// GET /api/v1/social/digital-marketing/assets — body `{ items: [...], total }`.
  Future<Map<String, dynamic>> listDigitalMarketingAssets({
    int limit = 30,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/social/digital-marketing/assets',
    ).replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});
    final response = await httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'items': <dynamic>[], 'total': 0};
    }
    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load campaigns (${response.statusCode})',
    );
  }

  static String? _httpDetailMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/v1/customers/list
  Future<List<Map<String, dynamic>>> listCustomers() async {
    final response = await httpClient.get(Uri.parse('$baseUrl/customers/list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }
    if (response.statusCode == 401) throw Exception('Session expired');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load customers (${response.statusCode})',
    );
  }

  /// GET /api/v1/customers/get/{customerId}
  Future<Map<String, dynamic>> getCustomer(int customerId) async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/customers/get/$customerId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) throw Exception('Session expired');
    if (response.statusCode == 404) throw Exception('Customer not found');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to load customer (${response.statusCode})',
    );
  }

  /// POST /api/v1/customers/add
  Future<Map<String, dynamic>> addCustomer({
    required String name,
    required String customerNumber,
    String? network,
    String? bankCode,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'customer_number': customerNumber.trim(),
    };
    if (network != null && network.trim().isNotEmpty) {
      body['network'] = network.trim();
    }
    if (bankCode != null && bankCode.trim().isNotEmpty) {
      body['bank_code'] = bankCode.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final response = await httpClient.post(
      Uri.parse('$baseUrl/customers/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) throw Exception('Session expired');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to add customer (${response.statusCode})',
    );
  }

  /// PUT /api/v1/customers/update/{customerId}
  Future<Map<String, dynamic>> updateCustomer(
    int customerId, {
    required String name,
    required String customerNumber,
    String? network,
    String? bankCode,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'customer_number': customerNumber.trim(),
    };
    if (network != null && network.trim().isNotEmpty) {
      body['network'] = network.trim();
    }
    if (bankCode != null && bankCode.trim().isNotEmpty) {
      body['bank_code'] = bankCode.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final response = await httpClient.put(
      Uri.parse('$baseUrl/customers/update/$customerId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) throw Exception('Session expired');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to update customer (${response.statusCode})',
    );
  }

  /// DELETE /api/v1/customers/delete/{customerId}
  Future<void> deleteCustomer(int customerId) async {
    final response = await httpClient.delete(
      Uri.parse('$baseUrl/customers/delete/$customerId'),
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 401) throw Exception('Session expired');
    if (response.statusCode == 404) throw Exception('Customer not found');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to delete customer (${response.statusCode})',
    );
  }

  /// POST /api/v1/customers/message/sms
  Future<Map<String, dynamic>> sendCustomerSms({
    required List<int> customerIds,
    required String message,
  }) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/customers/message/sms'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_ids': customerIds,
        'message': message.trim(),
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) throw Exception('Session expired');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to send SMS (${response.statusCode})',
    );
  }

  /// POST /api/v1/customers/message/email
  Future<Map<String, dynamic>> sendCustomerEmail({
    required List<int> customerIds,
    required String subject,
    required String body,
  }) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/customers/message/email'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_ids': customerIds,
        'subject': subject.trim(),
        'body': body,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    if (response.statusCode == 401) throw Exception('Session expired');
    throw Exception(
      _httpDetailMessage(response.body) ??
          'Failed to send email (${response.statusCode})',
    );
  }
}
