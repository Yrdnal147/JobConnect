import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DioClient {
  DioClient._();

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['MASTRA_BASE_URL'] ?? 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 300), // 5 minutes pour les workflows IA
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteur : ajoute automatiquement le token Supabase
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}