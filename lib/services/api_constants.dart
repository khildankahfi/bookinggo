class ApiConstants {
  // Ganti dengan IP laptop kamu jika test di HP fisik
  // Jika pakai emulator Android: 10.0.2.2
  // Jika pakai HP fisik: IP laptop (cek dengan ipconfig/ifconfig)
  static const String baseUrl = 'http://192.168.x.x:8000/api';

  // Auth
  static const String login    = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout   = '$baseUrl/logout';
  static const String profile  = '$baseUrl/profile';

  // Venues
  static const String venues = '$baseUrl/venues';
  static String venueDetail(int id) => '$baseUrl/venues/$id';
  static String venueAvailability(int id) => '$baseUrl/venues/$id/availability';

  // Bookings
  static const String bookings = '$baseUrl/bookings';
  static String cancelBooking(int id) => '$baseUrl/bookings/$id/cancel';
}