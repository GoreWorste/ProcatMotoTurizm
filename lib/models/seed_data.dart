import 'brand.dart';
import 'category.dart';
import 'client.dart';
import 'equipment.dart';
import 'rental_card.dart';
import 'tag.dart';

List<Category> seedCategories() => const [
      Category(id: 1, name: 'Палатки'),
      Category(id: 2, name: 'Велосипеды'),
      Category(id: 3, name: 'Мотоциклы'),
      Category(id: 4, name: 'Квадроциклы'),
      Category(id: 5, name: 'Водный транспорт'),
      Category(id: 6, name: 'Снегоходы'),
    ];

List<Brand> seedBrands() => const [
      Brand(id: 1, name: 'Tramp'),
      Brand(id: 2, name: 'Stels'),
      Brand(id: 3, name: 'Yamaha'),
      Brand(id: 4, name: 'Polaris'),
      Brand(id: 5, name: 'Trek'),
      Brand(id: 6, name: 'Sea-Doo'),
      Brand(id: 7, name: 'Buran'),
    ];

List<Tag> seedTags() => const [
      Tag(id: 1, name: 'зима'),
      Tag(id: 2, name: 'лето'),
      Tag(id: 3, name: 'для новичков'),
      Tag(id: 4, name: 'экстрим'),
      Tag(id: 5, name: 'водный'),
    ];

List<Equipment> seedEquipment() => [
      Equipment(id: 1, name: 'Палатка Tramp Lite 2', inventoryNumber: 'EQ-1001', categoryId: 1, brandId: 1, purchaseYear: 2021, dailyRate: 450, condition: 'хорошее', unitsTotal: 8, unitsAvailable: 5, tagIds: [2, 3]),
      Equipment(id: 2, name: 'Палатка Tramp Alpine 4', inventoryNumber: 'EQ-1002', categoryId: 1, brandId: 1, purchaseYear: 2020, dailyRate: 780, condition: 'новое', unitsTotal: 4, unitsAvailable: 4, tagIds: [1, 2]),
      Equipment(id: 3, name: 'Велосипед Trek Marlin 7', inventoryNumber: 'EQ-2001', categoryId: 2, brandId: 5, purchaseYear: 2022, dailyRate: 600, condition: 'хорошее', unitsTotal: 6, unitsAvailable: 3, tagIds: [2, 3]),
      Equipment(id: 4, name: 'Велосипед Stels Navigator 610', inventoryNumber: 'EQ-2002', categoryId: 2, brandId: 2, purchaseYear: 2019, dailyRate: 350, condition: 'требует обслуживания', unitsTotal: 10, unitsAvailable: 7, tagIds: [2, 3]),
      Equipment(id: 5, name: 'Мотоцикл Yamaha XT660R', inventoryNumber: 'EQ-3001', categoryId: 3, brandId: 3, purchaseYear: 2018, dailyRate: 3200, condition: 'хорошее', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 4]),
      Equipment(id: 6, name: 'Мотоцикл Stels Flame 200', inventoryNumber: 'EQ-3002', categoryId: 3, brandId: 2, purchaseYear: 2023, dailyRate: 1800, condition: 'новое', unitsTotal: 5, unitsAvailable: 4, tagIds: [2, 3, 4]),
      Equipment(id: 7, name: 'Квадроцикл Stels ATV 500', inventoryNumber: 'EQ-4001', categoryId: 4, brandId: 2, purchaseYear: 2020, dailyRate: 4500, condition: 'хорошее', unitsTotal: 4, unitsAvailable: 2, tagIds: [2, 4]),
      Equipment(id: 8, name: 'Квадроцикл Polaris Sportsman 570', inventoryNumber: 'EQ-4002', categoryId: 4, brandId: 4, purchaseYear: 2021, dailyRate: 5200, condition: 'новое', unitsTotal: 2, unitsAvailable: 2, tagIds: [1, 2, 4]),
      Equipment(id: 9, name: 'Гидроцикл Sea-Doo Spark Trixx', inventoryNumber: 'EQ-5001', categoryId: 5, brandId: 6, purchaseYear: 2022, dailyRate: 6800, condition: 'новое', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 5]),
      Equipment(id: 10, name: 'Каяк двухместный Tramp', inventoryNumber: 'EQ-5002', categoryId: 5, brandId: 1, purchaseYear: 2019, dailyRate: 900, condition: 'хорошее', unitsTotal: 12, unitsAvailable: 9, tagIds: [2, 5, 3]),
      Equipment(id: 11, name: 'Снегоход Buran LE', inventoryNumber: 'EQ-6001', categoryId: 6, brandId: 7, purchaseYear: 2017, dailyRate: 4100, condition: 'требует обслуживания', unitsTotal: 2, unitsAvailable: 0, tagIds: [1, 3]),
      Equipment(id: 12, name: 'Снегоход Yamaha VK540', inventoryNumber: 'EQ-6002', categoryId: 6, brandId: 3, purchaseYear: 2020, dailyRate: 5500, condition: 'хорошее', unitsTotal: 3, unitsAvailable: 2, tagIds: [1, 4]),
      Equipment(id: 13, name: 'Палатка Tramp Wind 3', inventoryNumber: 'EQ-1003', categoryId: 1, brandId: 1, purchaseYear: 2024, dailyRate: 520, condition: 'новое', unitsTotal: 6, unitsAvailable: 6, tagIds: [2]),
      Equipment(id: 14, name: 'Велосипед Trek FX 3', inventoryNumber: 'EQ-2003', categoryId: 2, brandId: 5, purchaseYear: 2023, dailyRate: 550, condition: 'новое', unitsTotal: 4, unitsAvailable: 2, tagIds: [2, 3]),
      Equipment(id: 15, name: 'Мотоцикл Yamaha MT-07', inventoryNumber: 'EQ-3003', categoryId: 3, brandId: 3, purchaseYear: 2022, dailyRate: 4800, condition: 'хорошее', unitsTotal: 2, unitsAvailable: 1, tagIds: [2, 4]),
      Equipment(id: 16, name: 'Квадроцикл Stels Guepard 800', inventoryNumber: 'EQ-4003', categoryId: 4, brandId: 2, purchaseYear: 2019, dailyRate: 3900, condition: 'хорошее', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 4]),
      Equipment(id: 17, name: 'SUP-доска Sea-Doo', inventoryNumber: 'EQ-5003', categoryId: 5, brandId: 6, purchaseYear: 2021, dailyRate: 1200, condition: 'хорошее', unitsTotal: 8, unitsAvailable: 6, tagIds: [2, 5]),
      Equipment(id: 18, name: 'Снегоход Buran 4T', inventoryNumber: 'EQ-6003', categoryId: 6, brandId: 7, purchaseYear: 2023, dailyRate: 4700, condition: 'новое', unitsTotal: 2, unitsAvailable: 2, tagIds: [1]),
      Equipment(id: 19, name: 'Палатка Tramp Family 6', inventoryNumber: 'EQ-1004', categoryId: 1, brandId: 1, purchaseYear: 2018, dailyRate: 1100, condition: 'требует обслуживания', unitsTotal: 3, unitsAvailable: 1, tagIds: [2, 3]),
      Equipment(id: 20, name: 'Велосипед Stels Flash 2.0', inventoryNumber: 'EQ-2004', categoryId: 2, brandId: 2, purchaseYear: 2024, dailyRate: 420, condition: 'новое', unitsTotal: 7, unitsAvailable: 5, tagIds: [2, 3, 4]),
      Equipment(id: 21, name: 'Мотоцикл Stels Delta 200', inventoryNumber: 'EQ-3004', categoryId: 3, brandId: 2, purchaseYear: 2020, dailyRate: 1500, condition: 'хорошее', unitsTotal: 4, unitsAvailable: 3, tagIds: [3]),
      Equipment(id: 22, name: 'Катамаран Sea-Doo Switch', inventoryNumber: 'EQ-5004', categoryId: 5, brandId: 6, purchaseYear: 2024, dailyRate: 8900, condition: 'новое', unitsTotal: 1, unitsAvailable: 1, tagIds: [2, 5, 4]),
    ];

RentalCard _card(String number, DateTime issued) =>
    RentalCard(number: number, issuedAt: issued);

List<Client> seedClients() => [
      Client(id: 1, fullName: 'Иванов Алексей Петрович', email: 'ivanov@example.ru', phone: '+7 (912) 345-67-01', city: 'Екатеринбург', registeredAt: DateTime(2022, 3, 12), rentalCard: _card('RC-00001', DateTime(2022, 3, 12))),
      Client(id: 2, fullName: 'Петрова Мария Сергеевна', email: 'petrova@example.ru', phone: '+7 (922) 111-22-33', city: 'Челябинск', registeredAt: DateTime(2021, 11, 5), rentalCard: _card('RC-00002', DateTime(2021, 11, 5))),
      Client(id: 3, fullName: 'Сидоров Дмитрий Игоревич', email: 'sidorov@example.ru', phone: '+7 (343) 555-44-22', city: 'Екатеринбург', registeredAt: DateTime(2023, 1, 20), rentalCard: _card('RC-00003', DateTime(2023, 1, 20))),
      Client(id: 4, fullName: 'Козлова Анна Викторовна', email: 'kozlova@example.ru', phone: '+7 (912) 777-88-99', city: 'Пермь', registeredAt: DateTime(2020, 7, 8), rentalCard: _card('RC-00004', DateTime(2020, 7, 8))),
      Client(id: 5, fullName: 'Новиков Павел Олегович', email: 'novikov@example.ru', phone: '+7 (351) 200-30-40', city: 'Челябинск', registeredAt: DateTime(2024, 2, 14), rentalCard: _card('RC-00005', DateTime(2024, 2, 14))),
      Client(id: 6, fullName: 'Морозова Елена Андреевна', email: 'morozova@example.ru', phone: '+7 (912) 900-11-22', city: 'Тюмень', registeredAt: DateTime(2022, 9, 30), rentalCard: _card('RC-00006', DateTime(2022, 9, 30))),
      Client(id: 7, fullName: 'Волков Артём Николаевич', email: 'volkov@example.ru', phone: '+7 (922) 333-44-55', city: 'Пермь', registeredAt: DateTime(2023, 6, 18), rentalCard: _card('RC-00007', DateTime(2023, 6, 18))),
      Client(id: 8, fullName: 'Смирнова Ольга Дмитриевна', email: 'smirnova@example.ru', phone: '+7 (343) 666-77-88', city: 'Екатеринбург', registeredAt: DateTime(2021, 4, 2), rentalCard: _card('RC-00008', DateTime(2021, 4, 2))),
      Client(id: 9, fullName: 'Фёдоров Кирилл Александрович', email: 'fedorov@example.ru', phone: '+7 (912) 123-45-67', city: 'Тюмень', registeredAt: DateTime(2024, 8, 1), rentalCard: _card('RC-00009', DateTime(2024, 8, 1))),
    ];
