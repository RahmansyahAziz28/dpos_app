// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'package:dpos/component/Appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: ' ',
  );

  String tanggal = '';
  String total_harga = '';
  String total_potongan = '';
  String omset = '';
  int jumlah = 0;
  bool isLoading = false;

  List<dynamic> laporanList = [];

  String dropdownValue = 'Penjualan';
  TextEditingController _dateController1 = TextEditingController();
  TextEditingController _dateController2 = TextEditingController();
  late TextEditingController _searchController = TextEditingController();
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchdata();
    });
  }

  @override
  void dispose() {
    _dateController1.dispose();
    _dateController2.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('dropdownValue', dropdownValue);
    prefs.setString('date1', _dateController1.text);
    prefs.setString('date2', _dateController2.text);
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    String currentDate = DateFormat('dd-MM-yyyy').format(now);

    setState(() {
      dropdownValue = prefs.getString('dropdownValue') ?? 'Penjualan';
      _dateController1.text = prefs.getString('date1') ?? currentDate;
      _dateController2.text = prefs.getString('date2') ?? currentDate;
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Future<void> fetchdata() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token = prefs.getString('token');
  //   List<String>? dataLocal = prefs.getStringList('local_permanent');
  //   int? user_id = prefs.getInt('user_id');
  //   print("data local: $dataLocal");
  //   String kategori;
  //   if (dropdownValue == 'Pembelian') {
  //     kategori = 'pengeluaran';
  //   } else if (dropdownValue == 'Penjualan') {
  //     kategori = 'pemasukan';
  //   } else {
  //     kategori = dropdownValue;
  //     kategori = kategori.toLowerCase();
  //   }
  //   String date1Formatted = DateFormat('yyyy-MM-dd').format(
  //     DateFormat('dd-MM-yyyy').parse(_dateController1.text),
  //   );
  //   String date2Formatted = DateFormat('yyyy-MM-dd').format(
  //     DateFormat('dd-MM-yyyy').parse(_dateController2.text),
  //   );

  //   bool isConnected = await _checkInternetConnection();
  //  String enableStokLimitParam = kategori == 'stok' && _isChecked
  //       ? '&enable_stok_limit=$_isChecked'
  //       : '';

  //   if (isConnected == true) {
  //     try {
  //       print(
  //           'https://dposlite.my.id/api/getlaporan?&tanggal_awal=$date1Formatted&tanggal_akhir=$date2Formatted&filter=$kategori$enableStokLimitParam&search_barang=${_searchController.text}');

  //       final response = await http.get(
  //         Uri.parse(
  //           'https://dposlite.my.id/api/getlaporan?&tanggal_awal=$date1Formatted&tanggal_akhir=$date2Formatted&filter=$kategori$enableStokLimitParam&search_barang=${_searchController.text}',
  //         ),
  //         headers: {
  //           'Accept': 'application/json',
  //           'Authorization': 'Bearer $token',
  //         },
  //       );

  //       if (response.statusCode == 200) {
  //         var responseBody = jsonDecode(response.body);
  //         print("Response Body: $responseBody");

  //         var laporanData = responseBody['data'];

  //         if (laporanData != null) {
  //           prefs.setString('laporanData', jsonEncode(laporanData));

  //           setState(() {
  //             laporanList = laporanData;
  //             print(laporanList);
  //             isLoading = false;
  //           });

  //           print("data api: $laporanList");
  //         } else {
  //           print("No data found");
  //         }
  //       } else {}
  //     } catch (error) {
  //       print('Error fetching data: $error');
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   } else {
  //     if (dataLocal != null) {
  //       Map<String, Map<String, dynamic>> aggregatedData =
  //           {};

  //       print('Selected Category: $kategori');

  //       for (var transactionJson in dataLocal) {
  //         try {
  //           var transaction = jsonDecode(transactionJson);

  //           if (transaction.containsKey('user_id') &&
  //               transaction['user_id'] == user_id) {
  //             if (transaction.containsKey('kategori')) {
  //               String transactionCategory =
  //                   transaction['kategori'].toString().trim().toLowerCase();
  //               print('Transaction Category: $transactionCategory');

  //               if (transactionCategory == kategori) {
  //                 if (transaction['tanggal_transaksi'] is String) {
  //                   String tanggal =
  //                       transaction['tanggal_transaksi'].split('T')[0];

  //                   DateTime transactionDate = DateTime.parse(tanggal);
  //                   DateTime startDate = DateTime.parse(date1Formatted);
  //                   DateTime endDate = DateTime.parse(date2Formatted);

  //                   if (transactionDate.isAfter(startDate) &&
  //                           transactionDate.isBefore(endDate) ||
  //                       transactionDate.isAtSameMomentAs(startDate) ||
  //                       transactionDate.isAtSameMomentAs(endDate)) {
  //                     double totalHarga = double.tryParse(
  //                             transaction['total_harga']
  //                                 .toString()
  //                                 .replaceAll('.', '')
  //                                 .replaceAll(',', '')) ??
  //                         0;
  //                     double potongan = double.tryParse(transaction['potongan']
  //                             .toString()
  //                             .replaceAll('.', '')
  //                             .replaceAll(',', '')) ??
  //                         0;

  //                     if (!aggregatedData.containsKey(tanggal)) {
  //                       aggregatedData[tanggal] = {
  //                         'tanggal_transaksi': DateFormat('dd/MM/yyyy')
  //                             .format(DateTime.parse(tanggal)),
  //                         'total_penjualan': 0,
  //                         'total_harga': 0,
  //                         'total_potongan': 0,
  //                         'omset': 0,
  //                       };
  //                     }

  //                     aggregatedData[tanggal]!['total_penjualan'] =
  //                         aggregatedData[tanggal]!['total_penjualan'] +
  //                             1;
  //                     aggregatedData[tanggal]!['total_harga'] =
  //                         aggregatedData[tanggal]!['total_harga'] + totalHarga;
  //                     aggregatedData[tanggal]!['total_potongan'] =
  //                         aggregatedData[tanggal]!['total_potongan'] + potongan;
  //                     aggregatedData[tanggal]!['omset'] = aggregatedData[
  //                         tanggal]!['total_harga'];
  //                   }
  //                 } else {
  //                   print('Invalid date format for transaction: $transaction');
  //                 }
  //               } else {
  //                 print(
  //                     'Transaction category does not match filter: $transaction');
  //               }
  //             } else {
  //               print('Kategori field is missing in transaction: $transaction');
  //             }
  //           } else {
  //             print('Transaction user_id does not match: $transaction');
  //           }
  //         } catch (e) {
  //           print('Error processing transaction data: $e');
  //         }
  //       }

  //       // Konversi aggregatedData ke dalam list
  //       List<Map<String, dynamic>> laporanData = aggregatedData.values.toList();

  //       prefs.setString('laporanData', jsonEncode(laporanData));

  //       setState(() {
  //         print("Filtered data: $laporanData");
  //         laporanList = laporanData;
  //         isLoading = false;
  //       });
  //     } else {
  //       setState(() {
  //         isLoading = false;
  //         laporanList = [];
  //       });
  //     }
  //   }
  // }

  Future<void> fetchdata() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    List<String>? dataLocal = prefs.getStringList('local_permanent');
    int? user_id = prefs.getInt('user_id');

    String kategori = dropdownValue.toLowerCase() == 'pembelian'
        ? 'pengeluaran'
        : dropdownValue.toLowerCase() == 'penjualan'
            ? 'pemasukan'
            : dropdownValue.toLowerCase();

    String date1Formatted = DateFormat('yyyy-MM-dd').format(
      DateFormat('dd-MM-yyyy').parse(_dateController1.text),
    );
    String date2Formatted = DateFormat('yyyy-MM-dd').format(
      DateFormat('dd-MM-yyyy').parse(_dateController2.text),
    );

    bool isConnected = await _checkInternetConnection();
    String enableStokLimitParam = kategori == 'stok' && _isChecked
        ? '&enable_stok_limit=$_isChecked'
        : '';

    if (isConnected) {
      try {
        final response = await http.get(
          Uri.parse(
            'https://dposlite.my.id/api/getlaporan?&tanggal_awal=$date1Formatted&tanggal_akhir=$date2Formatted&filter=$kategori$enableStokLimitParam&search_barang=${_searchController.text}',
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(            'https://dposlite.my.id/api/getlaporan?&tanggal_awal=$date1Formatted&tanggal_akhir=$date2Formatted&filter=$kategori$enableStokLimitParam&search_barang=${_searchController.text}',);
        if (response.statusCode == 200) {
          var responseBody = jsonDecode(response.body);
          var laporanData = responseBody['data'];

          if (laporanData != null) {
            dropdownValue == 'Stok' || dropdownValue == 'Terlaris'
                ? laporanData
                : laporanData.sort((a, b) =>
                    DateTime.parse(b['tanggal_transaksi'])
                        .compareTo(DateTime.parse(a['tanggal_transaksi'])));
                
            prefs.setString('laporanData', jsonEncode(laporanData));
            print('data api: $laporanData');
            setState(() {
              laporanList = laporanData;
              isLoading = false;
            });
          } else {
            print("No data found");
          }
        } else {
          print("Failed to fetch data");
        }
      } catch (error) {
        print('Error fetching data: $error');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (dataLocal != null) {
        Map<String, Map<String, dynamic>> aggregatedData = {};

        for (var transactionJson in dataLocal) {
          try {
            var transaction = jsonDecode(transactionJson);

            if (transaction['user_id'] == user_id &&
                transaction['kategori'].toString().trim().toLowerCase() ==
                    kategori) {
              String tanggal = transaction['tanggal_transaksi'].split('T')[0];

              DateTime transactionDate = DateTime.parse(tanggal);
              DateTime startDate = DateTime.parse(date1Formatted);
              DateTime endDate = DateTime.parse(date2Formatted);

              if ((transactionDate.isAfter(startDate) &&
                      transactionDate.isBefore(endDate)) ||
                  transactionDate.isAtSameMomentAs(startDate) ||
                  transactionDate.isAtSameMomentAs(endDate)) {
                double totalHarga = double.tryParse(transaction['total_harga']
                        .toString()
                        .replaceAll('.', '')) ??
                    0;
                double potongan = double.tryParse(transaction['potongan']
                        .toString()
                        .replaceAll('.', '')) ??
                    0;

                aggregatedData.putIfAbsent(
                    tanggal,
                    () => {
                          'tanggal_transaksi':
                              DateFormat('dd/MM/yyyy').format(transactionDate),
                          'total_penjualan': 0,
                          'total_harga': 0,
                          'total_potongan': 0,
                          'omset': 0,
                        });

                aggregatedData[tanggal]!['total_penjualan'] += 1;
                aggregatedData[tanggal]!['total_harga'] += totalHarga;
                aggregatedData[tanggal]!['total_potongan'] += potongan;
                aggregatedData[tanggal]!['omset'] =
                    aggregatedData[tanggal]!['total_harga'];
              }
            }
          } catch (e) {
            print('Error processing transaction data: $e');
          }
        }

        // Konversi aggregatedData ke dalam list dan urutkan
        List<Map<String, dynamic>> laporanData = aggregatedData.values.toList();
        laporanData.sort((a, b) => DateTime.parse(b['tanggal_transaksi'])
            .compareTo(DateTime.parse(a['tanggal_transaksi'])));

        prefs.setString('laporanData', jsonEncode(laporanData));

        setState(() {
          laporanList = laporanData;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          laporanList = [];
        });
      }
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xff2dbcf1),
            colorScheme: ColorScheme.light(primary: Color(0xff2dbcf1)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
        _savePreferences();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: CustomAppBar(),
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
                padding: EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      "LAPORAN",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Color(0xff2dbcf1),
                      ),
                    ),
                    Divider(
                      color: Color(0xff20c0fa),
                      height: 16,
                      thickness: 1,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Color(0xfffff200),
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(25, 0, 5, 0),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: dropdownValue,
                                icon: Icon(Icons.arrow_drop_down, size: 24),
                                elevation: 16,
                                style: TextStyle(
                                  color: Color(0xff000000),
                                  fontWeight: FontWeight.w500,
                                ),
                                underline: Container(
                                  height: 2,
                                  color: Colors.transparent,
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue = newValue!;
                                    fetchdata();
                                    _savePreferences();
                                  });
                                },
                                items: <String>[
                                  'Penjualan',
                                  'Pembelian',
                                  'Profit',
                                  'Terlaris',
                                  'Stok'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Center(child: Text(value)),
                                  );
                                }).toList(),
                                dropdownColor:
                                    Color.fromARGB(255, 255, 255, 255),
                                menuMaxHeight: 250,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (dropdownValue == 'Stok') ...[
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _searchController,
                                textAlign: TextAlign.left,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xff888888),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xffffffff),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                        color: Color(0xff000000), width: 0.3),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                        color: Color.fromARGB(255, 45, 45, 45),
                                        width: 1.2),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: () =>
                                    _selectDate(context, _dateController1),
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: _dateController1,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xffffffff),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 15),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(
                                            color: Color(0xff000000),
                                            width: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              width: 15,
                              height: 2,
                              color: Color(0xff000000),
                            ),
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: () =>
                                    _selectDate(context, _dateController2),
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: _dateController2,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xffffffff),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 15),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(
                                            color: Color(0xff000000),
                                            width: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (dropdownValue == 'Stok') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Limit Stok :',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff000000),
                            ),
                          ),
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                            activeColor: Color(0xff20c0fa),
                          ),
                        ],
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                            child: InkWell(
                              onTap: () {
                                fetchdata();
                              },
                              child: Container(
                                width: 55,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xff20c0fa),
                                ),
                                child: Center(
                                  child: Text(
                                    "view",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff000000),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Divider(
                            color: Color(0xff808080),
                            height: 16,
                          ),
                          isLoading
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: SpinKitThreeBounce(
                                    color: Color(0xff2dbcf1),
                                    size: 25.0,
                                  ),
                                )
                              : laporanList.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Text(
                                        "Tidak Ada Data",
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 18,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ),
                                    )
                                  : Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          Divider(
                                            color: Color(0xff808080),
                                            height: 16,
                                          ),
                                          isLoading
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 16),
                                                  child: SpinKitThreeBounce(
                                                    color: Color(0xff2dbcf1),
                                                    size: 25.0,
                                                  ),
                                                )
                                              : laporanList.isEmpty
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 16),
                                                      child: Text(
                                                        "Tidak Ada Data",
                                                        textAlign:
                                                            TextAlign.center,
                                                        overflow:
                                                            TextOverflow.clip,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontStyle:
                                                              FontStyle.normal,
                                                          fontSize: 18,
                                                          color: Color.fromARGB(
                                                              255, 0, 0, 0),
                                                        ),
                                                      ),
                                                    )
                                                  : Expanded(
                                                      child: LayoutBuilder(
                                                        builder: (context,
                                                            constraints) {
                                                          final width =
                                                              constraints
                                                                  .maxWidth;

                                                          final currencyFormatter =
                                                              NumberFormat
                                                                  .simpleCurrency(
                                                            locale: 'id_ID',
                                                            name: '',
                                                            decimalDigits: 0,
                                                          );

                                                          return SingleChildScrollView(
                                                            child: Column(
                                                              children: [
                                                                Table(
                                                                  border:
                                                                      TableBorder
                                                                          .all(
                                                                    color: Color(
                                                                        0xff000000),
                                                                    width: 1,
                                                                  ),
                                                                  columnWidths:
                                                                      dropdownValue == 'Stok' ||
                                                                              dropdownValue == 'Terlaris'
                                                                          ? {
                                                                              0: FixedColumnWidth(width * 0.6),
                                                                              1: FixedColumnWidth(width * 0.4),
                                                                            }
                                                                          : {
                                                                              0: FixedColumnWidth(width * 0.35),
                                                                              1: FixedColumnWidth(width * 0.25),
                                                                              2: FixedColumnWidth(width * 0.4),
                                                                            },
                                                                  children: [
                                                                    TableRow(
                                                                      children: dropdownValue == 'Stok' ||
                                                                              dropdownValue == 'Terlaris'
                                                                          ? [
                                                                              Container(
                                                                                alignment: Alignment.center,
                                                                                padding: EdgeInsets.fromLTRB(5, 3, 0, 3),
                                                                                child: Text(
                                                                                  'Nama barang',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 13,
                                                                                    color: Color(0xff000000),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Container(
                                                                                alignment: Alignment.center,
                                                                                padding: EdgeInsets.fromLTRB(3, 3, 0, 3),
                                                                                child: Text(
                                                                                  dropdownValue == 'Stok' ? 'Stok' : 'Penjualan',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 13,
                                                                                    color: Color(0xff000000),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Container(),
                                                                            ]
                                                                          : [
                                                                              Container(
                                                                                alignment: Alignment.center,
                                                                                padding: EdgeInsets.fromLTRB(5, 3, 0, 3),
                                                                                child: Text(
                                                                                  'Tanggal',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 13,
                                                                                    color: Color(0xff000000),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Container(
                                                                                alignment: Alignment.center,
                                                                                padding: EdgeInsets.fromLTRB(3, 3, 0, 3),
                                                                                child: Text(
                                                                                  'Transaksi',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 13,
                                                                                    color: Color(0xff000000),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Container(
                                                                                alignment: Alignment.center,
                                                                                padding: EdgeInsets.fromLTRB(0, 3, 5, 3),
                                                                                child: Text(
                                                                                  dropdownValue == 'Profit' ? 'Profit' : 'Omset',
                                                                                  style: TextStyle(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 13,
                                                                                    color: Color(0xff000000),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                    ),
                                                                    for (var laporan
                                                                        in laporanList)
                                                                      TableRow(
                                                                        children: dropdownValue == 'Stok' ||
                                                                                dropdownValue == 'Terlaris'
                                                                            ? [
                                                                                Container(
                                                                                  alignment: Alignment.center,
                                                                                  padding: EdgeInsets.fromLTRB(5, 3, 0, 3),
                                                                                  child: Text(
                                                                                    laporan['nama_barang'] ?? '',
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w500,
                                                                                      fontSize: 13,
                                                                                      color: Color(0xff000000),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  alignment: Alignment.center,
                                                                                  padding: EdgeInsets.fromLTRB(3, 3, 0, 3),
                                                                                  child: Text(
                                                                                    dropdownValue == 'Stok' ? (_isChecked ? "${laporan['stok_limit'] ?? 0}" : "${laporan['stok']}") : "${laporan['jumlah_terjual'] ?? 0}",
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w400,
                                                                                      fontSize: 13,
                                                                                      color: Color(0xff000000),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(),
                                                                              ]
                                                                            : [
                                                                                Container(
                                                                                  alignment: Alignment.center,
                                                                                  padding: EdgeInsets.fromLTRB(5, 3, 0, 3),
                                                                                  child: Text(
                                                                                    laporan['tanggal_transaksi'] ?? '',
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w500,
                                                                                      fontSize: 13,
                                                                                      color: Color(0xff000000),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  alignment: Alignment.center,
                                                                                  padding: EdgeInsets.fromLTRB(3, 3, 0, 3),
                                                                                  child: Text(
                                                                                    "${laporan['total_penjualan'] ?? 0}",
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w400,
                                                                                      fontSize: 13,
                                                                                      color: Color(0xff000000),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  alignment: Alignment.center,
                                                                                  padding: EdgeInsets.fromLTRB(0, 3, 5, 3),
                                                                                  child: Text(
                                                                                    dropdownValue == 'Profit' ? currencyFormatter.format(int.tryParse(laporan['profit']?.toString().replaceAll('.0000', '').replaceAll(',', '') ?? '0') ?? 0) : currencyFormatter.format(double.tryParse(laporan['omset']?.toString() ?? '0') ?? 0),
                                                                                    style: TextStyle(
                                                                                      fontWeight: FontWeight.w500,
                                                                                      fontSize: 11,
                                                                                      color: Color(0xff000000),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                      ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
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
        ],
      ),
    );
  }
}
