import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart'; // Ajuste le chemin selon ton projet
//import '../../core/network/api_endpoints.dart';

abstract class IMastraRemoteDataSource {
  Future<Map<String, dynamic>> executeAgent(String endpoint, dynamic input);
  Future<Map<String, dynamic>> startWorkflow(String endpoint, dynamic input);
}

@LazySingleton(as: IMastraRemoteDataSource)
class MastraRemoteDataSource implements IMastraRemoteDataSource {
  final Dio _dio = DioClient.instance;

  @override
  Future<Map<String, dynamic>> executeAgent(String endpoint, dynamic input) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: {
          'messages': [
            {'role': 'user', 'content': input}
          ]
        },
      );

      if (response.statusCode == 200) {
        // Mastra renvoie généralement un objet contenant la clé 'text' ou 'object' 
        // selon si le format de sortie est textuel ou structuré (Zod)
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception("Erreur de l'agent Mastra: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception("Échec de la communication avec l'agent : ${e.message}");
    }
  }

  @override
  Future<Map<String, dynamic>> startWorkflow(String endpoint, dynamic input) async {
    try {
      print('=============================================');
      print('🚀 TENTATIVE DE POST SUR : $endpoint');
      print('🚀 PAYLOAD : $input');
      print('=============================================');
      final response = await _dio.post(
        endpoint,
        data: {
          'input': input,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception("Erreur du Workflow Mastra: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      print('❌ ERREUR DIO SUR LE WORKFLOW: ${e.message}');
      print('❌ TYPE: ${e.type}');
      print('❌ ERREUR COMPLETE: $e');
      throw Exception("Échec de la communication avec le Workflow : ${e.message}");
    }
  }
}