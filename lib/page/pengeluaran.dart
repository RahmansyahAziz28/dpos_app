// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dpos/component/Rupiahformatter.dart';
import 'package:dpos/component/jumlahformatter.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:dpos/component/Appbar.dart';
import 'package:dpos/page/homepage.dart';
import 'package:dpos/page/konfirmasi.dart';
import 'package:dpos/page/setting.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NonNegativeNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.contains('-')) {
      return oldValue;
    }
    return newValue;
  }
}

class TransactionCodeGenerator {
  final Uuid _uuid = Uuid();

  String generateTransactionCode() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MM').format(now);
    String uuid = _uuid.v4();

    String transactionCode = 'B-${formattedDate}${uuid.substring(0, 6)}';

    return transactionCode;
  }
}

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  final TransactionCodeGenerator codeGenerator = TransactionCodeGenerator();
  final NumberFormat numberFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

  String transactionCode = "";
  String store = "";
  String phone = "";
  String? selectedDeviceAddress;
  String? selectedBarang;
  String? formattedKembalian = "0";
  String? formattedTotalBersih;
  Color cursorColor = Colors.black;
  bool resize = true;
  bool isLoading = false;
  bool showSuggestions = false;
  bool istype = false;

  double totalall = 0;
  double totalbersih = 0;
  double kembalian = 0;

  late TextEditingController caricontroller = TextEditingController();
  late TextEditingController barucontroller = TextEditingController();
  late TextEditingController potongancontroller = TextEditingController();
  late TextEditingController bayarcontroller = TextEditingController();
  late TextEditingController totalcontroller = TextEditingController();

  List<TextEditingController> barangControllers = [];
  List<TextEditingController> jumlahControllers = [];
  List<TextEditingController> hargaSatuanControllers = [];
  List<TextEditingController> hargaTotalControllers = [];

  List<int?> idList = [];
  List<String> barangList = [];
  List<String> jumlahList = [];
  List<String> hargaSatuanList = [];
  List<String> hargaTotalList = [];
  List<dynamic> databarang = [];
  List<dynamic> filteredBarang = [];
  List<String> originalNamaBarang = [];
  List<int> originalIdBarang = [];

  FocusNode cariFocusNode = FocusNode();
  FocusNode baruFocusNode = FocusNode();

  void hapusCard(int index) {
    setState(() {
      idList.removeAt(index);
      barangControllers.removeAt(index);
      jumlahControllers.removeAt(index);
      hargaSatuanControllers.removeAt(index);
      hargaTotalControllers.removeAt(index);

      hitungTotal();
    });
  }

  bool _validateInputs() {
    if (barangControllers.isEmpty ||
        hargaSatuanControllers.isEmpty ||
        hargaTotalControllers.isEmpty ||
        jumlahControllers.isEmpty ||
        bayarcontroller.text.isEmpty ||
        kembalian == 0 ||
        totalall == 0) {
      return false;
    }

    return true;
  }

  void fetchdata() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    bool isConnected = await _checkInternetConnection();

    if (isConnected != false) {
      try {
        final response = await http.get(
          Uri.parse('https://dposlite.my.id/api/getbarang'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          var responseJson = jsonDecode(response.body);
          var data = responseJson;
          print('Data: $data');
          List<String>? dataLocal = prefs.getStringList('local_transactions');
          print('local: $dataLocal');

          if (data is List) {
            await prefs.setString('databarang', jsonEncode(data));

            setState(() {
              databarang = data.map((item) {
                if (item is Map<String, dynamic>) {
                  return {
                    'id': item['id'] ?? 0,
                    'nama_barang': item['nama_barang']?.toString() ?? 'Unknown',
                    'harga_pokok': (item['harga_pokok']?.toString() ?? '0')
                        .replaceAll('.00', ''),
                  };
                }
                return {'nama_barang': 'Invalid item', 'harga_pokok': '0'};
              }).toList();
              isLoading = false;
            });
          } else {
            print('Unexpected data format: $data');
            setState(() {
              isLoading = false;
            });
          }
        } else {
          print('Error: ${response.statusCode}');
          setState(() {
            isLoading = false;
          });
        }
      } catch (error) {
        // setState(() {
        //   isLoading = false;
        // });
        print('Exception: $error');
      }
    } else {
      String? localData = prefs.getString('databarang');
      print('data local: $localData');
      if (localData != null) {
        var data = jsonDecode(localData);
        setState(() {
          databarang = data.map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'id': item['id'] ?? 0,
                'nama_barang': item['nama_barang']?.toString() ?? 'Unknown',
                'harga_pokok': (item['harga_pokok']?.toString() ?? '0')
                    .replaceAll('.00', ''),
              };
            }
            return {'nama_barang': 'Invalid item', 'harga_pokok': '0'};
          }).toList();
          isLoading = false;
        });
      } else {
        print('No local data found');
        setState(() {
          isLoading = false;
          databarang = [];
        });
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void loadSelectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      store = prefs.getString('store') ?? "";
      phone = prefs.getString('phone') ?? "";
    });
    selectedDeviceAddress = prefs.getString('selectedDeviceAddress');
  }

  Future<void> showValidationDialog(
      BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void changescrolltype() {
    setState(() {
      istype = false;
    });
  }

  void hitungTotal() {
    double potongan = double.tryParse(
            potongancontroller.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0;
    double bayar = double.tryParse(
            bayarcontroller.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0;

    double totalHarga = 0;

    for (int i = 0; i < jumlahControllers.length; i++) {
      double jumlah = double.tryParse(jumlahControllers[i]
              .text
              .replaceAll('.', '.')
              .replaceAll(',', '.')) ??
          0;
      double hargaSatuan = double.tryParse(hargaSatuanControllers[i]
              .text
              .replaceAll('.', '')
              .replaceAll(',', '.')) ??
          0;

      double hargaTotal = jumlah * hargaSatuan;
      hargaTotalControllers[i].text = numberFormat.format(hargaTotal);
      print(jumlah);
      totalHarga += hargaTotal;
    }

    totalbersih = totalHarga;

    if (potongan > totalHarga) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.red[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  potongancontroller.clear();
                  Navigator.of(context).pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Maaf, potongan tidak bisa melebihi harga total.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    double totalSetelahPotongan = totalHarga - potongan;

    totalcontroller.text = numberFormat.format(totalSetelahPotongan);

    double kembalianValue = bayar - totalSetelahPotongan;
    kembalian = (kembalianValue > 0) ? kembalianValue : 0;

    setState(() {
      totalall = totalSetelahPotongan;
      formattedKembalian = numberFormat.format(kembalian);
      totalcontroller.text = numberFormat.format(totalSetelahPotongan);
      formattedTotalBersih = numberFormat.format(totalbersih);
    });
  }

  List<TextInputFormatter> getInputFormatters(String initialInput) {
    if (initialInput.startsWith('0') || initialInput.isEmpty) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*$')),
        CustomRupiahFormatter(),
      ];
    } else {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*$')),
        RupiahFormatter(),
      ];
    }
  }

  void tambahCard(String namaBarang, String hargaJual, {int? idBarang}) {
    setState(() {
      bool barangAda = false;

      if (barangControllers.isEmpty || barangControllers[0].text.isEmpty) {
        if (barangControllers.isEmpty) {
          barangControllers.add(TextEditingController(text: namaBarang));
          jumlahControllers.add(TextEditingController());
          hargaSatuanControllers.add(TextEditingController(text: hargaJual));
          hargaTotalControllers.add(TextEditingController());

          idList.add(idBarang ?? 0);
          originalIdBarang.add(idBarang ?? 0);
          originalNamaBarang.add(namaBarang);
        } else {
          barangControllers[0].text = namaBarang;
          jumlahControllers[0].text = "1";
          hargaSatuanControllers[0].text = hargaJual;

          // Update id dan nama asli
          idList[0] = idBarang ?? 0;
          originalIdBarang[0] = idBarang ?? 0;
          originalNamaBarang[0] = namaBarang;
        }

        hitungTotal();
        return;
      }

      for (int i = 0; i < barangControllers.length; i++) {
        if (barangControllers[i].text == namaBarang) {
          int jumlah = int.tryParse(jumlahControllers[i].text) ?? 0;
          jumlahControllers[i].text = (jumlah + 1).toString();
          barangAda = true;
          break;
        }
      }

      if (!barangAda) {
        barangControllers.add(TextEditingController(text: namaBarang));
        jumlahControllers.add(TextEditingController(text: "1"));
        hargaSatuanControllers.add(TextEditingController(text: hargaJual));
        hargaTotalControllers.add(TextEditingController());

        // Tambahkan id dan nama barang asli
        idList.add(idBarang ?? 0);
        originalIdBarang.add(idBarang ?? 0);
        originalNamaBarang.add(namaBarang);
      }

      hitungTotal();
    });
  }

  void simpanSemuaDataKeList() {
    barangList.clear();
    jumlahList.clear();
    hargaSatuanList.clear();
    hargaTotalList.clear();

    for (int i = 0; i < barangControllers.length; i++) {
      barangList.add(barangControllers[i].text);
      jumlahList.add(jumlahControllers[i].text);
      hargaSatuanList.add(hargaSatuanControllers[i].text);
      hargaTotalList.add(hargaTotalControllers[i].text);
    }

    print('Barang List: $barangList');
    print('Jumlah List: $jumlahList');
    print('ID List: $idList');
    print('Harga Satuan List: $hargaSatuanList');
    print('Harga Total List: $hargaTotalList');
  }

  OverlayEntry? overlayEntry;

  void showSuggestionsOverlay(BuildContext context) {
    if (overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final double width = renderBox.size.width;

    if (filteredBarang.isEmpty) {
      removeSuggestionsOverlay();
      return;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + 15,
        top: position.dy + 283,
        width: width - 16,
        child: Material(
          color: Colors.white,
          elevation: 5,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 250,
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filteredBarang.length,
              itemBuilder: (context, index) {
                var barang = filteredBarang[index];
                String namaBarang = barang['nama_barang'] ?? 'Unknown';

                String hargaBarangString = barang['harga_pokok'] ?? '0';
                int hargaBarang = int.tryParse(hargaBarangString) ?? 0;

                String formattedHargaBarang = numberFormat.format(hargaBarang);

                int? idBarang;

                if (barang['id'] is int) {
                  idBarang = barang['id'];
                } else if (barang['id'] is String) {
                  idBarang = int.tryParse(barang['id']) ?? 0;
                } else {
                  idBarang = 0;
                }

                String displayText = '$namaBarang@$formattedHargaBarang';

                return ListTile(
                  title:
                      Text(displayText, style: TextStyle(color: Colors.black)),
                  onTap: () {
                    removeSuggestionsOverlay();
                    setState(() {
                      caricontroller.text = "";
                      tambahCard(namaBarang, formattedHargaBarang,
                          idBarang: idBarang);
                      print("ID barang yang dipilih: $idBarang");
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry!);
  }

  void removeSuggestionsOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  void onCariChanged(String value) {
    if (value.isNotEmpty) {
      Set<String> seenNames = {};
      filteredBarang = databarang.where((barang) {
        String namaBarang = barang['nama_barang'] ?? '';

        if (namaBarang.toLowerCase().contains(value.toLowerCase()) &&
            !seenNames.contains(namaBarang)) {
          seenNames.add(namaBarang);
          return true;
        }
        return false;
      }).toList();

      if (filteredBarang.isNotEmpty) {
        removeSuggestionsOverlay();
        showSuggestionsOverlay(context);
      } else {
        removeSuggestionsOverlay();
      }
    } else {
      filteredBarang = [];
      removeSuggestionsOverlay();
    }
  }

  @override
  void initState() {
    super.initState();
    tambahCard("", '');
    fetchdata();
    loadSelectedDevice();
    transactionCode = codeGenerator.generateTransactionCode();
  }

  @override
  void dispose() {
    barucontroller.dispose();
    for (var controller in barangControllers) {
      controller.dispose();
    }
    for (var controller in jumlahControllers) {
      controller.dispose();
    }
    for (var controller in hargaSatuanControllers) {
      controller.dispose();
    }
    for (var controller in hargaTotalControllers) {
      controller.dispose();
    }
    cariFocusNode.dispose();
    baruFocusNode.dispose();
    removeSuggestionsOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String currenttime = DateFormat("yyyy-MM-dd'T'HH:mm").format(now);
    String displayTime = currenttime.replaceAll('T', ' ');

    return GestureDetector(
      onTap: () {
        removeSuggestionsOverlay();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: resize,
        backgroundColor: Color(0xffffffff),
        appBar: CustomAppBar(
          removeSuggestionsOverlay: removeSuggestionsOverlay,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment(0.0, 0.0),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: GestureDetector(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          "PEMBELIAN",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontSize: 18,
                            color: Color(0xff2dbcf1),
                          ),
                        ),
                        Divider(
                          color: Color(0xff20c0fa),
                          height: 16,
                          thickness: 1,
                          indent: 12,
                          endIndent: 12,
                        ),
                        SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(transactionCode),
                              Text(displayTime),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 6, 0, 0),
                          child: TextField(
                            controller: totalcontroller,
                            obscureText: false,
                            textAlign: TextAlign.right,
                            enabled: false,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 33,
                              color: Color(0xff000000),
                            ),
                            decoration: InputDecoration(
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                    color: Color(0xff000000), width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                    color: Color(0xff000000), width: 0.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                    color: Color(0xff000000), width: 0.5),
                              ),
                              hintText: "0",
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontSize: 35,
                                color: Color(0xff000000),
                              ),
                              filled: false,
                              fillColor: Color(0xffffffff),
                              isDense: false,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                            inputFormatters: [
                              RupiahFormatter(),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: caricontroller,
                                focusNode: cariFocusNode,
                                obscureText: false,
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 13,
                                  color: Color(0xff000000),
                                ),
                                decoration: InputDecoration(
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                        color: Color(0xff000000), width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                        color: Color(0xff000000), width: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                        color: Color(0xff000000), width: 0.5),
                                  ),
                                  hintText: "Cari...",
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                    fontSize: 14,
                                    color: Color(0xff000000),
                                  ),
                                  filled: false,
                                  fillColor: Color(0xffffffff),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                ),
                                onChanged: onCariChanged,
                                cursorColor: cursorColor,
                                onTap: () {
                                  setState(() {
                                    istype = false;
                                    resize = false;
                                    FocusScope.of(context)
                                        .requestFocus(cariFocusNode);
                                    baruFocusNode.unfocus();
                                  });
                                },
                              ),
                            ),
                            Container(
                              color: Color(0xff20c0fa),
                              height: 37,
                              padding: EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 2),
                              child: IconButton(
                                icon: Icon(Icons.add, color: Colors.white),
                                onPressed: () {
                                  if (caricontroller.text.isNotEmpty) {
                                    removeSuggestionsOverlay();

                                    tambahCard(caricontroller.text, '');
                                    caricontroller.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            child: GridView(
                              padding: EdgeInsets.all(0),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              //  istype
                              // ? NeverScrollableScrollPhysics()
                              // : AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.5,
                              ),
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Container(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      height: 664,
                                      child: ListView.builder(
                                        physics:
                                            //  istype
                                            // ?
                                            NeverScrollableScrollPhysics(),
                                        // : AlwaysScrollableScrollPhysics(),
                                        itemCount: barangControllers.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return Card(
                                            margin: EdgeInsets.zero,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            elevation: 0,
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        hapusCard(index);
                                                      },
                                                      child: Icon(
                                                        Icons.clear,
                                                        color:
                                                            Color(0xffff0000),
                                                        size: 22,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: TextField(
                                                        controller:
                                                            barangControllers[
                                                                index],
                                                        obscureText: false,
                                                        enableInteractiveSelection:
                                                            false,
                                                        textAlign:
                                                            TextAlign.start,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontStyle:
                                                              FontStyle.normal,
                                                          fontSize: 13,
                                                          color:
                                                              Color(0xff000000),
                                                        ),
                                                        decoration:
                                                            InputDecoration(
                                                          disabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          hintText:
                                                              "Nama Barang",
                                                          hintStyle: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontStyle: FontStyle
                                                                .normal,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xff000000),
                                                          ),
                                                          filled: false,
                                                          fillColor:
                                                              Color(0xfff2f2f3),
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          8,
                                                                      horizontal:
                                                                          12),
                                                        ),
                                                        cursorColor:
                                                            cursorColor,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            if (value !=
                                                                originalNamaBarang[
                                                                    index]) {
                                                              idList[index] = 0;
                                                            } else {
                                                              idList[index] =
                                                                  originalIdBarang[
                                                                      index];
                                                            }
                                                          });
                                                        },
                                                        onSubmitted: (value) {
                                                          setState(() {
                                                            istype = false;
                                                          });
                                                        },
                                                        onTap: () {
                                                          setState(() {
                                                            istype = true;
                                                            resize = false;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      flex: 1,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                22, 0, 0, 0),
                                                        child: TextField(
                                                          controller:
                                                              jumlahControllers[
                                                                  index],
                                                          keyboardType:
                                                              TextInputType
                                                                  .numberWithOptions(
                                                                      decimal:
                                                                          true),
                                                          
                                                          obscureText: false,
                                                          textAlign:
                                                              TextAlign.right,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontStyle: FontStyle
                                                                .normal,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xff000000),
                                                          ),
                                                          decoration:
                                                              InputDecoration(
                                                            disabledBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero,
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xff000000),
                                                                  width: 0.3),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero,
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xff000000),
                                                                  width: 0.3),
                                                            ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero,
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xff000000),
                                                                  width: 0.3),
                                                            ),
                                                            hintText: "jumlah",
                                                            hintStyle:
                                                                TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .normal,
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                            filled: false,
                                                            fillColor: Color(
                                                                0xfff2f2f3),
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            8,
                                                                        horizontal:
                                                                            12),
                                                          ),
                                                          inputFormatters:
                                                          //  getInputFormatters(jumlahControllers[index].text),
                                                          // jumlahControllers[index]
                                                          //         .text
                                                          //         .startsWith(
                                                          //             "0.")
                                                          //     ? [
                                                                  [CustomRupiahFormatter()],
                                                          //       ]
                                                          //     : [
                                                          //         RupiahFormatter()
                                                          //       ],

                                                          cursorColor:
                                                              cursorColor,
                                                          onSubmitted: (value) {
                                                            setState(() {
                                                              istype = false;
                                                            });
                                                          },
                                                          onTap: () {
                                                            setState(() {
                                                              istype = true;
                                                              resize = false;
                                                            });
                                                          },
                                                          onChanged: (value) =>
                                                              hitungTotal(),
                                                        ),
                                                    ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: TextField(
                                                        controller:
                                                            hargaSatuanControllers[
                                                                index],
                                                        enableInteractiveSelection:
                                                            false,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        obscureText: false,
                                                        textAlign:
                                                            TextAlign.right,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontStyle:
                                                              FontStyle.normal,
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xff000000),
                                                        ),
                                                        decoration:
                                                            InputDecoration(
                                                          disabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          hintText: "@harga",
                                                          hintStyle: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontStyle: FontStyle
                                                                .normal,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xff000000),
                                                          ),
                                                          filled: false,
                                                          fillColor:
                                                              Color(0xfff2f2f3),
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          8,
                                                                      horizontal:
                                                                          12),
                                                        ),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'[0-9.]')),
                                                          RupiahFormatter()
                                                        ],
                                                        cursorColor:
                                                            cursorColor,
                                                        onSubmitted: (value) {},
                                                        onTap: () {
                                                          setState(() {
                                                            resize = false;
                                                            istype = true;
                                                          });
                                                        },
                                                        onChanged: (value) {
                                                          int actualValue =
                                                              int.parse(value
                                                                  .replaceAll(
                                                                      RegExp(
                                                                          r'[^0-9]'),
                                                                      ''));
                                                          print(
                                                              "Nilai asli: $actualValue");
                                                          hitungTotal();
                                                        },
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: TextField(
                                                        controller:
                                                            hargaTotalControllers[
                                                                index],
                                                        enabled: false,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        obscureText: false,
                                                        textAlign:
                                                            TextAlign.right,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontStyle:
                                                              FontStyle.normal,
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xff000000),
                                                        ),
                                                        decoration:
                                                            InputDecoration(
                                                          disabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff000000),
                                                                width: 0.3),
                                                          ),
                                                          hintText: "0",
                                                          hintStyle: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontStyle: FontStyle
                                                                .normal,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xff000000),
                                                          ),
                                                          filled: false,
                                                          fillColor:
                                                              Color(0xfff2f2f3),
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          8,
                                                                      horizontal:
                                                                          12),
                                                        ),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'[0-9.]')),
                                                          RupiahFormatter()
                                                        ],
                                                        onSubmitted: (value) {},
                                                        onTap: () {
                                                          setState(() {
                                                            resize = false;
                                                            istype = true;
                                                          });
                                                        },
                                                        onChanged: (value) =>
                                                            hitungTotal(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: Color(0xff808080),
                          height: 16,
                          thickness: 0,
                          indent: 0,
                          endIndent: 0,
                        ),
                        istype
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 0, 0, 8),
                                          child: Text(
                                            "total",
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 0, 0, 8),
                                          child: Text(
                                            "potongan",
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 0, 0, 8),
                                          child: Text(
                                            "bayar",
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 0, 0, 0),
                                          child: Text(
                                            "kembalian",
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 0, 12, 5),
                                          child: Text(
                                            "$formattedTotalBersih",
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30,
                                          child: TextField(
                                              controller: potongancontroller,
                                              keyboardType:
                                                  TextInputType.number,
                                              obscureText: false,
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                              decoration: InputDecoration(
                                                disabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                filled: true,
                                                hintText: "0",
                                                hintStyle: TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff000000),
                                                ),
                                                fillColor: Color(0x00f2f2f3),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.fromLTRB(
                                                        12, 0, 12, 8),
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'[0-9.]')),
                                                RupiahFormatter()
                                              ],
                                              cursorColor: cursorColor,
                                              onTap: () {
                                                setState(() {
                                                  resize = true;
                                                });
                                              },
                                              onChanged: (value) {
                                                hitungTotal();
                                              }),
                                        ),
                                        SizedBox(
                                          height: 30,
                                          child: TextField(
                                            controller: bayarcontroller,
                                            keyboardType: TextInputType.number,
                                            obscureText: false,
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                            decoration: InputDecoration(
                                              disabledBorder:
                                                  OutlineInputBorder(
                                                borderRadius: BorderRadius.zero,
                                                borderSide: BorderSide(
                                                    color: Color(0xff000000),
                                                    width: 0.3),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.zero,
                                                borderSide: BorderSide(
                                                    color: Color(0xff000000),
                                                    width: 0.3),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.zero,
                                                borderSide: BorderSide(
                                                    color: Color(0xff000000),
                                                    width: 0.3),
                                              ),
                                              hintText: "0",
                                              hintStyle: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                color: Color(0xff000000),
                                              ),
                                              filled: true,
                                              fillColor: Color(0x00f2f2f3),
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.fromLTRB(
                                                      12, 0, 12, 8),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'[0-9.]')),
                                              RupiahFormatter()
                                            ],
                                            cursorColor: cursorColor,
                                            onTap: () {
                                              setState(() {
                                                resize = true;
                                              });
                                            },
                                            onChanged: (value) => hitungTotal(),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 5, 12, 0),
                                          child: Text(
                                            "$formattedKembalian",
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                              color: Color(0xff000000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsets.fromLTRB(0, 0, 0, 8),
                                            child: Text(
                                              "total",
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.fromLTRB(0, 0, 0, 8),
                                            child: Text(
                                              "potongan",
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.fromLTRB(0, 0, 0, 8),
                                            child: Text(
                                              "bayar",
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.fromLTRB(0, 0, 0, 0),
                                            child: Text(
                                              "kembalian",
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                0, 0, 12, 5),
                                            child: Text(
                                              "$formattedTotalBersih",
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller: potongancontroller,
                                              keyboardType:
                                                  TextInputType.number,
                                              obscureText: false,
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                              decoration: InputDecoration(
                                                disabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                filled: true,
                                                hintText: "0",
                                                hintStyle: TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff000000),
                                                ),
                                                fillColor: Color(0x00f2f2f3),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.fromLTRB(
                                                        12, 0, 12, 8),
                                              ),
                                              cursorColor: cursorColor,
                                              onTap: () {
                                                setState(() {
                                                  resize = true;
                                                });
                                              },
                                              onChanged: (value) =>
                                                  hitungTotal(),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: TextField(
                                              controller: bayarcontroller,
                                              keyboardType:
                                                  TextInputType.number,
                                              obscureText: false,
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                              decoration: InputDecoration(
                                                disabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                      color: Color(0xff000000),
                                                      width: 0.3),
                                                ),
                                                hintText: "0",
                                                hintStyle: TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff000000),
                                                ),
                                                filled: true,
                                                fillColor: Color(0x00f2f2f3),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.fromLTRB(
                                                        12, 0, 12, 8),
                                              ),
                                              cursorColor: cursorColor,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'[0-9.]')),
                                                RupiahFormatter()
                                              ],
                                              onTap: () {
                                                setState(() {
                                                  resize = true;
                                                });
                                              },
                                              onChanged: (value) =>
                                                  hitungTotal(),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                0, 5, 12, 0),
                                            child: Text(
                                              "$formattedKembalian",
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff000000),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                MaterialButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Homepage()),
                    );
                  },
                  color: Color(0xffff0000),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Batal",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  textColor: Color(0xff000000),
                  height: 40,
                  minWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                MaterialButton(
                  onPressed: () async {
                    loadSelectedDevice();
                    if (barangControllers == null ||
                        jumlahControllers == null ||
                        hargaSatuanControllers == null ||
                        totalall == null ||
                        bayarcontroller == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Row(
                            children: <Widget>[
                              Icon(
                                Icons.error,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Harap isi data yang kosong terlebih dahulu!',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (store.isEmpty || phone.isEmpty) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            contentPadding: EdgeInsets.all(20),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  "Isi Nama Toko, nomor HP terlebih dahulu untuk lanjut ke halaman ini!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              Center(
                                child: TextButton(
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SettingPage()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (selectedDeviceAddress == null) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            contentPadding: EdgeInsets.all(20),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  "Anda belum memilih printer, isi terlebih dahulu atau pilih opsi tanpa nota",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  TextButton(
                                    child: Text(
                                      'Tanpa nota',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      simpanSemuaDataKeList();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => KonfirmasiPage(
                                            namaBarang: barangList,
                                            hargaSatuan: hargaSatuanList,
                                            harga_pokok: hargaSatuanList,
                                            jumlahbarang: jumlahList,
                                            hargaTotal: hargaTotalList,
                                            totalall: formattedTotalBersih,
                                            potongan:
                                                potongancontroller.text.isEmpty
                                                    ? "0"
                                                    : potongancontroller.text,
                                            bayar: bayarcontroller.text,
                                            kembalian: formattedKembalian,
                                            date: currenttime,
                                            idbarang: idList,
                                            kodetransaksi: transactionCode,
                                            Kategori: 'pengeluaran',
                                            opsiprint: false,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      'OK',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SettingPage()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    } else if (_validateInputs()) {
                      simpanSemuaDataKeList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KonfirmasiPage(
                            namaBarang: barangList,
                            hargaSatuan: hargaSatuanList,
                            harga_pokok: hargaSatuanList,
                            jumlahbarang: jumlahList,
                            hargaTotal: hargaTotalList,
                            totalall: formattedTotalBersih,
                            potongan: potongancontroller.text.isEmpty
                                ? "0"
                                : potongancontroller.text,
                            bayar: bayarcontroller.text,
                            kembalian: formattedKembalian,
                            date: currenttime,
                            idbarang: idList,
                            kodetransaksi: transactionCode,
                            Kategori: 'pengeluaran',
                            opsiprint: true,
                          ),
                        ),
                      );
                    }
                  },
                  color: Color(0xff20c0fa),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Cetak",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  textColor: Color(0xff000000),
                  height: 40,
                  minWidth: MediaQuery.of(context).size.width * 0.5,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
