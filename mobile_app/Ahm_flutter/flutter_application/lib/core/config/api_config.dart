class ApiConfig {
  static const bool useMock = true;

  // เปลี่ยนตอนมี backend จริง
  static const String baseUrl = 'http://10.0.2.2:8080';
  // Android Emulator ใช้ 10.0.2.2 แทน localhost
  // ถ้าเป็น web/ios/device จริง ค่อยเปลี่ยนอีกที
}