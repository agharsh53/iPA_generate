import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final _client = Supabase.instance.client;

  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('category_type', type.name)
        .order('id');

    return (response as List)
        .map((e) => Category.fromSupabase(e))
        .toList();
  }
}
