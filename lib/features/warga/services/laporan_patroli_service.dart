import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_client.dart';
import '../models/laporan_patroli_model.dart';

class LaporanPatroliService {
  Future<List<LaporanPatroliModel>> getLaporanPatroli({
    required String token,
    String? tanggal,
  }) async {
    final queryParams = <String, String>{};
    if (tanggal != null) queryParams['tanggal'] = tanggal;

    final uri = Uri.parse('${ApiClient.baseUrl}/warga/laporan-patroli')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: ApiClient.headers(token: token),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => LaporanPatroliModel.fromJson(e)).toList();
    }

    throw Exception(
        jsonDecode(response.body)['message'] ?? 'Gagal memuat laporan patroli');
  }
}
