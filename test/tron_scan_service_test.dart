import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:crypto_wallet/services/tron_scan_service.dart';
import 'dart:convert';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'tron_scan_service_test.mocks.dart';

void main() {
  group('TronScanService', () {
    late MockClient mockHttpClient;
    late TronScanService tronScanService;

    setUp(() {
      mockHttpClient = MockClient();
      tronScanService = TronScanService(client: mockHttpClient);
    });

    test('getTrxBalance returns correct balance when API call is successful', () async {
      // Arrange
      const testAddress = 'TGV1iNTZoEnxYPccZRxCScC9dKQdLhEYtX';
      final mockResponse = {
        'balance': 100000000, // 100 TRX in sun units
        'address': testAddress,
      };

      when(mockHttpClient.get(
        Uri.parse('https://apilist.tronscanapi.com/api/accountv2?address=$testAddress'),
      )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      // Act
      final balance = await tronScanService.getTrxBalance(testAddress);

      // Assert
      expect(balance, 100.0); // Should convert from sun to TRX (divide by 1,000,000)
      verify(mockHttpClient.get(
        Uri.parse('https://apilist.tronscanapi.com/api/accountv2?address=$testAddress'),
      )).called(1);
    });

    test('getTrxBalance returns 0 when balance is null', () async {
      // Arrange
      const testAddress = 'TGV1iNTZoEnxYPccZRxCScC9dKQdLhEYtX';
      final mockResponse = {
        'address': testAddress,
        'balance': null,
      };

      when(mockHttpClient.get(
        Uri.parse('https://apilist.tronscanapi.com/api/accountv2?address=$testAddress'),
      )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      // Act
      final balance = await tronScanService.getTrxBalance(testAddress);

      // Assert
      expect(balance, 0.0);
      verify(mockHttpClient.get(
        Uri.parse('https://apilist.tronscanapi.com/api/accountv2?address=$testAddress'),
      )).called(1);
    });

    test('getTrxBalance throws exception when API call fails', () async {
      // Arrange
      const testAddress = 'TGV1iNTZoEnxYPccZRxCScC9dKQdLhEYtX';

      when(mockHttpClient.get(
        Uri.parse('https://apilist.tronscanapi.com/api/accountv2?address=$testAddress'),
      )).thenAnswer((_) async => http.Response('Error', 404));

      // Act & Assert
      expect(
        () => tronScanService.getTrxBalance(testAddress),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          'Exception: Error getting TRX balance: Exception: Failed to load TRX balance',
        )),
      );
    });

    test('getTrxBalance handles network errors', () async {
      // Arrange
      const testAddress = 'TGV1iNTZoEnxYPccZRxCScC9dKQdLhEYtX';

      when(mockHttpClient.get(
        Uri.parse('https://apilist.tronscanapi.com/api/accountv2?address=$testAddress'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => tronScanService.getTrxBalance(testAddress),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Network error'),
        )),
      );
    });

    tearDown(() {
      // Clean up any resources
    });
  });
} 