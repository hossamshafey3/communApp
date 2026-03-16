import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://zgxfhebjrdkfnmqyfebv.supabase.co';
  static const String anonKey = 'sb_publishable_EhqJI2fJRelD02eJ_Zv25A_H3QfMsEI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
