import '../../../core/services/supabase_service.dart';
import '../models/buku_tamu_model.dart';

class BukuTamuService {
  Future<List<BukuTamuModel>> getBukuTamu({
    String? tanggal,
    String? search,
    String? status,
  }) async {
    final supabase = SupabaseService.client;

    dynamic query = supabase
        .from('tamu')
        .select('*')
        .order('id', ascending: false);

    if (tanggal != null) {
      query = query.gte('waktu_masuk', tanggal);
      query = query.lte('waktu_masuk', '$tanggal 23:59:59');
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('nama', '%$search%');
    }

    if (status != null && status != 'semua') {
      query = query.eq('status', status);
    }

    final List<dynamic> data = await query;
    return data.map((e) => BukuTamuModel.fromJson(e)).toList();
  }
}
