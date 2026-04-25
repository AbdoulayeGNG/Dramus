import 'package:dio/dio.dart';
import 'package:dramus/core/api/api_client.dart';
import 'package:dramus/models/agent_model.dart';
import 'package:flutter/foundation.dart';

class AgentService extends ChangeNotifier {
  final Dio _dio = ApiClient.I.dio;

  List<AgentModel> _agents = [];
  bool _isLoading = false;

  List<AgentModel> get agents => _agents;
  bool get isLoading => _isLoading;

  Future<void> fetchAgents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/api/agents');
      if (response.statusCode == 200) {
        // Backend might wrap in { success: true, data: [...] }
        final dynamic responseData = response.data;
        List<dynamic> list;
        if (responseData is Map && responseData.containsKey('data')) {
          list = responseData['data'];
        } else {
          list = responseData;
        }
        _agents = list.map((json) => AgentModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching agents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AgentModel?> getAgent(String id) async {
    try {
      final response = await _dio.get('/api/agents/$id');
      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        final data = (responseData is Map && responseData.containsKey('data'))
            ? responseData['data']
            : responseData;
        return AgentModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error getting agent: $e');
    }
    return null;
  }

  Future<bool> createAgent(AgentModel agent) async {
    try {
      final response = await _dio.post('/api/agents', data: agent.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchAgents();
        return true;
      }
    } catch (e) {
      debugPrint('Error creating agent: $e');
    }
    return false;
  }

  Future<bool> updateAgent(String id, AgentModel agent) async {
    try {
      final response = await _dio.put('/api/agents/$id', data: agent.toJson());
      if (response.statusCode == 200) {
        await fetchAgents();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating agent: $e');
    }
    return false;
  }

  Future<bool> deleteAgent(String id) async {
    try {
      final response = await _dio.delete('/api/agents/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _agents.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting agent: $e');
    }
    return false;
  }
}
