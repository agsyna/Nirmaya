import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/dataModel/common_user_model.dart';

String baseUrl = ""; // Default URL
bool fest = false;
bool easterEggs = false;

class Dioclient {
  static Dio? dio;

  // Static method to refresh JWT token using refresh token
  static Future<bool> refreshAccessToken(BuildContext? context) async {
    try {
      debugPrint('Attempting to refresh access token...');

      final refreshToken = CommonUserModel.refreshToken;
      final currentToken = CommonUserModel.token;

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available');
        CommonUserModel.clear();
        if (context != null && context.mounted) {
          context.go('/login');
        }
        return false;
      }

      // Call /auth/is-alive to refresh the token
      final response = await dio!.post(
        '/auth/is-alive',
        data: {'accessToken': currentToken},
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 201) {
        // Token refreshed successfully
        final responseData = response.data;
        debugPrint('Token refreshed successfully');

        // Update the new refresh token in memory
        CommonUserModel.refreshToken = responseData['refreshToken'];
        // Note: Persistent storage will be handled by AuthService when needed

        return true;
      } else if (response.statusCode == 401) {
        // Refresh token is also expired - logout
        debugPrint('Refresh token expired - logging out');
        CommonUserModel.clear();
        if (context != null && context.mounted) {
          context.go('/login');
        }
        return false;
      } else if (response.statusCode == 200) {
        // Token is still valid
        debugPrint('Token is still valid');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  static Future<void> initialize() async {
    baseUrl = 'https://api-uat-unisphere.bmu.edu.in/api/v2';
    debugPrint('------------------INITIAL BASE URL: $baseUrl');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('appDetails')
          .doc('h2EHwI2vznWyU6voyDBJ')
          .get();

      if (doc.exists) {
        baseUrl = doc.data()?['apiUrl'] as String? ?? baseUrl;
        fest = doc.data()?['fest'] as bool? ?? fest;
        easterEggs = doc.data()?['esterEggs'] as bool? ?? easterEggs;
        // fest = false;

        debugPrint("base url : $baseUrl");
        debugPrint("fest :::::::::::::::::::::::::::::::::::::::::::::::::::; $fest");

      }
    } catch (e) {

      debugPrint('Error fetching API URL from Firestore: $e');
      // Fall back to default URL
    }

    debugPrint('---------------FINAL BASE URL: $baseUrl');

    dio = Dio(
        BaseOptions(
          
          baseUrl: baseUrl,
          // baseUrl: 'https://api-uat-unisphere.bmu.edu.in/api/v2',
          // baseUrl: 'https://api.akashch.me/api/v2',
          
          // Fallback to default if Firestore fetch fails
        connectTimeout: Duration(seconds: 20),
        receiveTimeout: Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    BuildContext? context,
    bool isRetry = false,
  }) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }
      final token =
          CommonUserModel.isLoggedIn()
              ? "Bearer ${CommonUserModel.refreshToken!}"
              : "";

      return await dio!.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: {'Authorization': token}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !isRetry) {
        // Try to refresh token
        debugPrint('Got 401, attempting token refresh...');
        final refreshed = await refreshAccessToken(context);

        if (refreshed) {
          // Retry the request with new token
          debugPrint('Token refreshed, retrying request...');
          return await get(
            path,
            queryParameters: queryParameters,
            context: context,
            isRetry: true,
          );
        } else {
          throw Exception('Session expired. Please login again.');
        }
      } else {
        throw Exception('Failed to get data: $e');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  static Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
    BuildContext? context,
    bool isRetry = false,
  }) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }
      final token =
          CommonUserModel.isLoggedIn()
              ? "Bearer ${CommonUserModel.refreshToken}"
              : "";

      debugPrint("$data");

      return await dio!.post(
        path,
        data: data,
        options: Options(headers: {'Authorization': token}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !isRetry) {
        // Try to refresh token
        debugPrint('Got 401, attempting token refresh...');
        final refreshed = await refreshAccessToken(context);

        if (refreshed) {
          // Retry the request with new token
          debugPrint('Token refreshed, retrying request...');
          return await post(path, data: data, context: context, isRetry: true);
        } else {
          throw Exception('Session expired. Please login again.');
        }
      } else {
        throw Exception('Failed to post data: $e');
      }
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  static Future<Response> put(
    String path, {
    Map<String, dynamic>? data,
    BuildContext? context,
    bool isRetry = false,
  }) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }
      final token =
          CommonUserModel.isLoggedIn()
              ? "Bearer ${CommonUserModel.refreshToken}"
              : "";
      debugPrint(
        'DioClient PUT request to $path with data: $data and token: $token',
      );
      return await dio!.put(
        path,
        data: data,
        options: Options(headers: {'Authorization': token}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !isRetry) {
        // Try to refresh token
        debugPrint('Got 401, attempting token refresh...');
        final refreshed = await refreshAccessToken(context);

        if (refreshed) {
          // Retry the request with new token
          debugPrint('Token refreshed, retrying request...');
          return await put(path, data: data, context: context, isRetry: true);
        } else {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: 'Session expired. Please login again.',
            type: e.type,
          );
        }
      } else {
        // Re-throw the original DioException to preserve all response data
        rethrow;
      }
    } catch (e) {
      // For any other non-Dio exceptions, create a DioException
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Failed to update data: $e',
        type: DioExceptionType.unknown,
      );
    }
  }

  static Future<Response> delete(
    String path, {
    Map<String, dynamic>? data,
    BuildContext? context,
    bool isRetry = false,
  }) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }
      final token =
          CommonUserModel.isLoggedIn()
              ? "Bearer ${CommonUserModel.refreshToken}"
              : "";

      debugPrint(
        'DioClient DELETE request to $path with data: $data and token: $token',
      );
      return await dio!.delete(
        path,
        data: data,
        options: Options(headers: {'Authorization': token}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !isRetry) {
        // Try to refresh token
        debugPrint('Got 401, attempting token refresh...');
        final refreshed = await refreshAccessToken(context);

        if (refreshed) {
          // Retry the request with new token
          debugPrint('Token refreshed, retrying request...');
          return await delete(
            path,
            data: data,
            context: context,
            isRetry: true,
          );
        } else {
          throw Exception('Session expired. Please login again.');
        }
      } else {
        throw Exception('Failed to delete data: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  // SOLUTION 1: Return status instead of showing SnackBar directly
  static Future<bool> checkHealth(BuildContext context) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }
      final baseUrlWithoutApi = baseUrl.replaceAll(RegExp(r'/api/v2.*$'), '');
      final response = await dio!.get('$baseUrlWithoutApi/health-check');

      print(
        "-------------------------------SERVER STATUS----------------------${response.statusCode}",
      );
      if (response.statusCode == 200 || response.statusCode == 304) {
        return true;
      } else {
        debugPrint("Health check failed with status: ${response.statusCode}");
        return false;
      }
    } on DioException catch (e) {
      debugPrint("Health check failed: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("Unknown error: $e");
      return false;
    }
  }

  // SOLUTION 2: Safe SnackBar method with context validation
  static Future<bool> checkHealthWithSnackbar(BuildContext context) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }

      final response = await dio!.get('jai bhawani/health-check');
      if (response.statusCode == 200) {
        return true;
      } else {
        _showServerDownSnackBarSafe(context);
        return false;
      }
    } on DioException catch (e) {
      debugPrint("Health check failed: ${e.message}");
      _showServerDownSnackBarSafe(context);
      return false;
    } catch (e) {
      debugPrint("Unknown error: $e");
      _showServerDownSnackBarSafe(context);
      return false;
    }
  }

  // SOLUTION 3: Safe SnackBar helper with context validation
  static void _showServerDownSnackBarSafe(BuildContext context) {
    try {
      // Check if ScaffoldMessenger is available in the context
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Server is currently unavailable."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Fallback: Just log the error if no ScaffoldMessenger is available
        debugPrint(
          "Server is currently unavailable - No ScaffoldMessenger available to show SnackBar",
        );
      }
    } catch (e) {
      debugPrint("Error showing SnackBar: $e");
    }
  }

  // SOLUTION 4: Alternative method using a callback for error handling
  static Future<bool> checkHealthWithCallback({
    Function(String)? onError,
  }) async {
    try {
      if (Dioclient.dio == null) {
        Dioclient();
      }

      final response = await dio!.get('/health-check');
      if (response.statusCode == 200) {
        return true;
      } else {
        onError?.call("Server is currently unavailable.");
        return false;
      }
    } on DioException catch (e) {
      debugPrint("Health check failed: ${e.message}");
      onError?.call("Server is currently unavailable.");
      return false;
    } catch (e) {
      debugPrint("Unknown error: $e");
      onError?.call("Server is currently unavailable.");
      return false;
    }
  }

  // Keep the original method for backward compatibility (but deprecated)
  @deprecated
  static void showServerDownSnackBar(BuildContext context) {
    _showServerDownSnackBarSafe(context);
  }

  //Added by Mayank to upload files to S3 using a presigned URL
  static Future<bool> putFileToPresignedUrl(String uploadUrl, File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      final contentType = "image/${file.path.split('.').last}";

      final tempDio = Dio(); // No auth header here
      final response = await tempDio.put(
        uploadUrl,
        data: Stream.fromIterable([fileBytes]),
        options: Options(headers: {'Content-Type': contentType}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Failed to upload file to S3: $e");
      return false;
    }
  }
}
