// ignore_for_file: avoid_print

import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://lqouohvisoplazzooixg.supabase.co';
  final supabaseKey = 'sb_publishable_3SLBxEf0vAfDPxxvWUYy3w_u5W2l8RG';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Fetching profiles...');
  final profiles = await client.from('profiles').select();
  print(profiles);

  print('Fetching clinics...');
  final clinics = await client.from('clinics').select();
  print(clinics);

  print('Fetching clinic_memberships...');
  final memberships = await client.from('clinic_memberships').select();
  print(memberships);
}
