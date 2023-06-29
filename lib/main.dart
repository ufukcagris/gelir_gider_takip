import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ucs_gelir_gider/login_page.dart';


// Gelir ve gider kategorileri için bir enum tanımlıyoruz
enum Category { income, expense }

const storage = FlutterSecureStorage();

// Gelir ve gider kayıtlarını tutmak için bir sınıf tanımlıyoruz
class Record {
  String title; // Kaydın başlığı
  double amount; // Kaydın miktarı
  Category category; // Kaydın kategorisi
  int year; // Kaydın yapıldığı yıl
  int month; // Kaydın yapıldığı ay

  // Sınıfın kurucu fonksiyonu
  Record(this.title, this.amount, this.category, this.year, this.month);

  // Sınıfı JSON formatına dönüştüren fonksiyon
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category.index,
      'year': year,
      'month': month,
    };
  }

  // JSON formatından sınıfı oluşturan fonksiyon
  Record.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        amount = json['amount'],
        category = Category.values[json['category']],
        year = json['year'],
        month = json['month'];
}

// Uygulamanın ana sınıfı
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Uygulamanın başlangıç noktası
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gelir Gider Takip Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false
    );
  }
}

// Uygulamanın ana sayfasının sınıfı
class MyHomePage extends StatefulWidget {
  // Ana sayfanın başlığı
  final String title;

  // Sınıfın kurucu fonksiyonu
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // Sınıfın durumunu oluşturan fonksiyon
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// Uygulamanın ana sayfasının durumunu tutan sınıf
class _MyHomePageState extends State<MyHomePage> {
  // Gelir ve gider kayıtlarını tutan bir liste tanımlıyoruz
  List<Record> records = [];

  // Filtrelenmiş gelir ve gider kayıtlarını tutan bir liste tanımlıyoruz
  List<Record> filteredRecords = [];

  // SharedPreferences nesnesi tanımlıyoruz
  late SharedPreferences prefs;

  // Seçilen yılı tutan değişken tanımlıyoruz (varsayılan olarak şimdiki yıl)
  int selectedYear = DateTime.now().year;

  // Seçilen ayı tutan değişken tanımlıyoruz (varsayılan olarak şimdiki ay)
  int selectedMonth = DateTime.now().month;

  // Uygulama başladığında SharedPreferences nesnesini başlatan fonksiyon
  @override
  void initState() {
    super.initState();
    initPrefs();
    filteredRecords = filterRecords(selectedYear,
        selectedMonth); // Kayıtları filtreliyoruz - Bu satırı ekledim, böylece ilk açılışta filtrelenmiş kayıtlar gözükür.
  }

  // SharedPreferences nesnesini başlatan ve kaydedilmiş verileri okuyan fonksiyon
  void initPrefs() async {
    prefs = await SharedPreferences.getInstance(); // Nesneyi başlatıyoruz
    List<String> savedRecords =
        await loadPrefs(); // Kaydedilmiş verileri alıyoruz
    setState(() {
      records = savedRecords
          .map((e) => Record.fromJson(jsonDecode(e)))
          .toList(); // Verileri Record listesine dönüştürüyoruz
    });
  }

  // Verileri SharedPreferences nesnesine kaydeden fonksiyon
  void savePrefs() async {
    List<String> savedRecords = records
        .map((e) => jsonEncode(e.toJson()))
        .toList(); // Verileri JSON listesine dönüştürüyoruz
    await storage.write(
        key: 'records',
        value: jsonEncode(savedRecords)); // Verileri kaydediyoruz
  }

  // Flutter secure storage nesnesinden verileri okuyan fonksiyon
  Future<List<String>> loadPrefs() async {
    List<String> savedRecords = [];
    try {
      String? data = await storage.read(key: 'records');
      if (data != null) {
        savedRecords = List.from(jsonDecode(data) ?? []);
      }
    } catch (e) {
      print(e);
    }
    return savedRecords; // Kaydedilmiş verileri döndürüyoruz
  }

  // Gelir ve gider toplamlarını hesaplayan fonksiyon
  double getTotal(Category category) {
    double total = 0;
    for (Record record in filteredRecords) {
      if (record.category == category) {
        total += record.amount;
      }
    }
    return total;
  }

  // Kayıtları yıl ve aya göre filtreleyen fonksiyon
  List<Record> filterRecords(int year, int month) {
    return records
        .where((record) => record.year == year && record.month == month)
        .toList(); // Bu satırı kısalttım, for döngüsü yerine where metodu kullandım.
  }

  // Kaydı düzenlemek için bir diyalog gösteren fonksiyon
  void editRecord(int index) async {
    // Seçilen kaydı alıyoruz
    Record record = records[index];

    // Diyalogun sonucunu bekliyoruz
    bool? result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kaydı Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(
                labelText: 'Başlık',
                initialValue: record.title,
                onChanged: (value) {
                  record.title = value;
                },
              ),
              Container(
                padding: EdgeInsets.only(top:10),
                child: buildTextField(
                  labelText: 'Tutar',
                  initialValue: record.amount.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    record.amount = double.tryParse(value) ?? 0;
                  },
                ),
              ),
              buildRadioRow(record),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (validateRecord(record)) {
                  Navigator.pop(context, true);
                } else {
                  showWarning(
                      context, 'Lütfen geçerli bir başlık ve miktar giriniz.');
                }
              },
              child: const Text('Düzenle'),
            ),
          ],
        );
      },
    );

    // Diyalog sonucu doğruysa seçilen kaydın değerlerini güncelliyoruz ve verileri kaydediyoruz
    if (result == true) {
      setState(() {
        records[index] = record;
        filteredRecords = filterRecords(
            selectedYear, selectedMonth); // Kayıtları filtreliyoruz
      });
      savePrefs();
    }
  }

  // Yeni bir kayıt eklemek için bir diyalog gösteren fonksiyon
  void addRecord() async {
    // Yeni kaydı tutacak değişken tanımlıyoruz
    Record record = Record('', 0, Category.income, selectedYear, selectedMonth);

    // Diyalogun sonucunu bekliyoruz
    bool? result = await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(// Burada StatefulBuilder widgetını ekliyoruz
              builder: (context, setState) {
            // Burada kendi setState metodumuzu alıyoruz
            return AlertDialog(
              title: const Text('Yeni Kayıt Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTextField(
                    labelText: 'Başlık',
                    onChanged: (value) {
                      record.title = value;
                    },
                  ),
                  Container(
                    padding: EdgeInsets.only(top:10),
                    child: buildTextField(
                      labelText: 'Tutar',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        record.amount = double.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                  buildRadioRow(record),
                  // Burada radio butonlarını gösteriyoruz
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    if (validateRecord(record)) {
                      Navigator.pop(context, true);
                    } else {
                      showWarning(context,
                          'Lütfen geçerli bir başlık ve miktar giriniz.');
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          });
        });

    // Diyalog sonucu doğruysa yeni kaydı listeye ekliyoruz ve verileri kaydediyoruz
    if (result == true) {
      setState(() {
        records.add(record);
        filteredRecords = filterRecords(
            selectedYear, selectedMonth); // Kayıtları filtreliyoruz
      });
      savePrefs();
    }
  }

  // Bir TextField widgetını oluşturan fonksiyon
  Widget buildTextField({
    required String labelText,
    String? initialValue,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      controller: initialValue != null
          ? TextEditingController(text: initialValue)
          : null,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  // Bir Radio widgetlarını içeren bir Row widgetını oluşturan fonksiyon
  Widget buildRadioRow(Record record) {
    Category selectedCategory = record
        .category; // Burada seçilen kategoriyi tutacak bir değişken tanımlıyoruz
    return StatefulBuilder(// Burada StatefulBuilder widgetını ekliyoruz
        builder: (context, setState) {
      // Burada kendi setState metodumuzu alıyoruz
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text('Kategori'),
          Radio<Category>(
            value: Category.income,
            groupValue: selectedCategory,
            // Burada seçilen kategoriyi veriyoruz
            onChanged: (value) {
              setState(() {
                selectedCategory =
                    value!; // Burada seçilen kategoriyi güncelliyoruz
                record.category =
                    value; // Burada kaydın kategorisini güncelliyoruz
              });
            },
          ),
          const Text('Gelir'),
          Radio<Category>(
            value: Category.expense,
            groupValue: selectedCategory,
            // Burada seçilen kategoriyi veriyoruz
            onChanged: (value) {
              setState(() {
                selectedCategory =
                    value!; // Burada seçilen kategoriyi güncelliyoruz
                record.category =
                    value; // Burada kaydın kategorisini güncelliyoruz
              });
            },
          ),
          const Text('Gider'),
        ],
      );
    });
  }

  // Bir kaydın geçerli olup olmadığını kontrol eden fonksiyon
  bool validateRecord(Record record) {
    return record.title.isNotEmpty && record.amount >= 0;
  }

  // Bir uyarı mesajı gösteren fonksiyon
  void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Ana sayfanın arayüzünü oluşturan fonksiyon
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Column(
          children: [
            const Text(
              "Yücel Canpolat Gelir - Gider",
              style: TextStyle(fontSize: 15),
            ),
            Text(
              "$selectedYear / $selectedMonth",
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ), // Seçilen yıl ve ayı gösteriyoruz
        leading: IconButton(
          // Sol oku gösteriyoruz
          onPressed: () {
            decreaseYearOrMonth(); // Yıl veya ay değerini azaltıyoruz
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            // Sağ oku gösteriyoruz
            onPressed: () {
              increaseYearOrMonth(); // Yıl veya ay değerini arttırıyoruz
            },
            icon: const Icon(Icons.arrow_forward),
          ),
          IconButton(
            onPressed: selectYearAndMonth,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () {
              // Yardım tuşuna basıldığında bir diyalog penceresi gösteriyoruz
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Yardım'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('# Verileri sağa veya sola doğru kaydırarak silebilirsin.'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('# Verinin üzerine basılı tutarak girdiğin verileri düzeltebilirsin.'),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20, left: 100),
                          child: Text('Copyright © ufukcagris'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Diyalog penceresini kapatıyoruz
                          Navigator.of(context).pop();
                        },
                        child: const Text('Tamam'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredRecords.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Listenin ilk elemanı olarak gelir ve gider toplamlarını gösteren bir kart döndürüyoruz
            return buildTotalCard();
          } else {
            // Listenin diğer elemanları için kayıtları gösteren bir kart döndürüyoruz
            Record record = filteredRecords[index - 1];
            return buildRecordCard(record, index - 1);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: addRecord,
        tooltip: 'Yeni Kayıt Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Gelir ve gider toplamlarını gösteren bir kart widgetını oluşturan fonksiyon
  Widget buildTotalCard() {
    double income = getTotal(Category.income);
    double expense = getTotal(Category.expense);
    double balance = income - expense;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildColumn('Gelir', income, Colors.green),
            buildColumn('Gider', expense, Colors.red),
            buildColumn(
                'Bakiye', balance, balance >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  // Bir metin ve bir sayıyı belirli bir renkte gösteren bir sütun widgetını oluşturan fonksiyon
  Widget buildColumn(String text, double number, Color color) {
    return Column(
      children: [
        Text(text),
        Text("$number₺", style: TextStyle(color: color)),
      ],
    );
  }

  // Bir kaydı gösteren bir kart widgetını oluşturan fonksiyon
  Widget buildRecordCard(Record record, int index) {
    return Card(
      child: GestureDetector(
        onLongPress: () {
          editRecord(index);
        },
        child: Dismissible(
          key: Key(record.title.toString()),
          // We also need to provide a function that tells our app
          // what to do after an item has been swiped away.
          onDismissed: (direction) async {
            String item = record.title;
            // Remove the item from our data source.
            //fBtDoc.deleteTraveldoc (item);
            //Firestore.instance.collection ('/users/User1/Trips/$ {widget.tripId}/TropDocs/').document ('$itemID').delete ();
            setState(() {
              records.removeAt(index);
              filteredRecords = filterRecords(
                  selectedYear, selectedMonth); // Kayıtları filtreliyoruz
            });
            // Bir SnackBar widget'ı oluşturuyoruz
            final snackBar = SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  // Çöp kutusu ikonunu veriyoruz
                  const SizedBox(width: 10),
                  // İkon ile metin arasında bir boşluk veriyoruz
                  Text("$item silindi.",
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              // Mesaj metnini veriyoruz
              duration: const Duration(seconds: 10),
              // Mesajın ekranda kalma süresini veriyoruz
              backgroundColor: Colors.white,
              // Mesajın arka plan rengini veriyoruz
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    50), // Mesajın köşe yarıçaplarını veriyoruz
              ),
              action: SnackBarAction(
                label: 'Geri al', // Mesajın sağundaki butonun metnini veriyoruz
                onPressed: () {
                  setState(() {
                    records.insert(index,
                        record); // Butona basılırsa kaydı tekrar ekliyoruz
                    filteredRecords = filterRecords(
                        selectedYear, selectedMonth); // Kayıtları filtreliyoruz
                  });
                  // Burada snack_bar'ı kapatıyoruz
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                textColor: Colors.blue, // Butonun metin rengini veriyoruz
              ),
            );

// SnackBar widget'ını ekranda gösteriyoruz
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          // Show a red background as the item is swiped away
          background: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.red,
            ),
            alignment: Alignment.centerLeft, // İkonu sola hizalıyoruz
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.red,
            ),
            alignment: Alignment.centerRight, // İkonu sola hizalıyoruz
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          movementDuration: const Duration(seconds: 1),
          child: ListTile(
            title: Text(
              record.title,
              style: TextStyle(
                color: record.category == Category.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            subtitle:
                Text(record.category == Category.income ? "Gelir" : "Gider"),
            trailing: Text(
              record.amount.toString(),
              style: TextStyle(
                color: record.category == Category.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Kullanıcıya yıl ve ay seçtiren bir diyalog gösteren fonksiyon
  void selectYearAndMonth() async {
    // Diyalogun sonucunu bekliyoruz
    List<int>? result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yıl ve Ay Seçiniz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildDropdownButton<int>(
                labelText: 'Yıl',
                items: [2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030],
                value: selectedYear,
                onChanged: (value) {
                  setState(() {
                    selectedYear = value!;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.only(top:10),
                child: buildDropdownButton<int>(
                  labelText: 'Ay',
                  items: List.generate(12, (index) => index + 1),
                  value: selectedMonth,
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, [selectedYear, selectedMonth]);
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );

    // Diyalog sonucu doğruysa seçilen yıl ve ayı güncelliyoruz ve kayıtları filtreliyoruz
    if (result != null && result.length == 2) {
      setState(() {
        selectedYear = result[0];
        selectedMonth = result[1];
        filteredRecords = filterRecords(selectedYear, selectedMonth);
      });
    }
  }

  // Bir DropdownButton widgetını oluşturan fonksiyon
  Widget buildDropdownButton<T>({
    required String labelText,
    required List<T> items,
    required T value,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
          .toList(),
      value: value,
      onChanged: onChanged,
    );
  }

  // Yıl veya ay değerini arttıran fonksiyon
  void increaseYearOrMonth() {
    setState(() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
      filteredRecords =
          filterRecords(selectedYear, selectedMonth); // Kayıtları filtreliyoruz
    });
  }

  // Yıl veya ay değerini azaltan fonksiyon
  void decreaseYearOrMonth() {
    setState(() {
      if (selectedMonth == 1) {
        selectedMonth = 12;
        selectedYear--;
      } else {
        selectedMonth--;
      }
      filteredRecords =
          filterRecords(selectedYear, selectedMonth); // Kayıtları filtreliyoruz
    });
  }
}

// Uygulamayı çalıştıran fonksiyon
void main() async {
  runApp(const MyApp());
}
