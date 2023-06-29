import 'package:flutter/material.dart';

import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 100, top:200), // Container'a üstten boşluk veriyoruz
            child: Image(
              image: AssetImage('assets/logo.png'), // Logo resmini veriyoruz
              alignment: Alignment.center, // Resmi ortaya hizalıyoruz
              width: 200, // Resmin genişliğini veriyoruz
              height: 200, // Resmin yüksekliğini veriyoruz
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 40, right: 20, bottom: 100), // Container'a kenardan boşluk veriyoruz
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Sütunu aşağıya hizalıyoruz
              children: [
                Text(
                  'Merhaba. Hoşgeldiniz!',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left, // Metni sola hizalıyoruz
                ),
                SizedBox(height: 20),
                Container(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                    child: Text('GİRİŞ YAP'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(title: 'Gelir Gider Takip Sistemi',)));
                    },
                    style: ButtonStyle(
                      alignment:
                      Alignment.center, // Butonu sola hizalıyoruz// Butonun boyutunu veriyoruz
                      backgroundColor: MaterialStateProperty.all(Colors.blueGrey), // Butonun rengini veriyoruz
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // Butonun köşe yarıçapını veriyoruz
                        side: BorderSide(color: Colors.white, width: 2), // Butonun kenarlık rengini ve kalınlığını veriyoruz
                      )),
                      elevation: MaterialStateProperty.all(10), // Butonun gölge yüksekliğini veriyoruz
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
