import 'package:flutter_test/flutter_test.dart';
import 'package:tandau/services/roi_calculator_service.dart';
import 'package:tandau/models/profession.dart';
import 'package:tandau/models/university.dart';

void main() {
  final roiService = RoiCalculatorService();

  const mockProfession = Profession(
    id: 'it_dev',
    name: 'Разработчик ПО',
    nameKz: 'БҚ әзірлеушісі',
    startSalary: 400000,
    tuitionPerYear: 1000000,
    studyYears: 4,
    emoji: '💻',
  );

  final mockUniversity = University(
    id: 'kbtu',
    name: 'КБТУ',
    city: 'Алматы',
    logoUrl: '',
    imageUrls: [],
    majors: ['IT'],
    passingScore: 100,
    tuitionRange: '4 000 000',
    hasDormitory: true,
    hasGrants: true,
    description: '',
    requirements: [],
    applicationDeadline: '',
    address: '',
    website: '',
    studentCount: 5000,
  );

  group('RoiCalculatorService - Basic ROI', () {
    test('Calculate ROI for Paid Education', () {
      final result = roiService.calculate(
        profession: mockProfession,
        isGrant: false,
        university: mockUniversity,
        yearsToCalculate: 10,
      );

      expect(result.totalTuition, 4000000);
      expect(result.monthlySalary, 400000);
      // monthlySavings = 400000 * 0.35 = 140000
      // 4000000 / 140000 = 28.57 -> 29 months
      expect(result.paybackMonths, 29);
      expect(result.rating, RoiRating.excellent);
    });

    test('Calculate ROI for Grant', () {
      final result = roiService.calculate(
        profession: mockProfession,
        isGrant: true,
        university: mockUniversity,
      );

      expect(result.totalTuition, 0);
      expect(result.paybackMonths, 0);
      expect(result.rating, RoiRating.excellent);
    });
  });

  group('RoiCalculatorService - FinTech Analysis', () {
    test('Calculate FinTech Analysis for Paid Education', () {
      final analysis = roiService.calculateFinTechPortfolio(
        profession: mockProfession,
        university: mockUniversity,
        isGrant: false,
      );

      expect(analysis.professionName, 'Разработчик ПО');
      // Opportunity cost for 4M over 4 years at 14% interest should be > 1.5M
      expect(analysis.opportunityCost, greaterThan(1500000));
      
      // NPV should be positive for IT developer
      expect(analysis.npv, greaterThan(0));
      
      // Проверка финансового грейда
      expect(analysis.financialGrade, anyOf('AAA', 'AA', 'A'));
    });

    test('Grant Efficiency should be near 100%', () {
      final analysis = roiService.calculateFinTechPortfolio(
        profession: mockProfession,
        university: mockUniversity,
        isGrant: true,
      );

      expect(analysis.investmentReturnRate, 1.0);
      expect(analysis.financialGrade, 'AAA');
      expect(analysis.opportunityCost, 0);
    });
  });
}
