// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:io';

import 'package:dpos/component/Appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final numberFormatter = NumberFormat.decimalPattern('id');

  String dropdownValue = 'Penjualan';
  String kode_transaksi = '';
  String tanggal_transaksi = '';
  String total_harga = '';
  String potongan = '';
  String jumlah_dibayar = '';
  String kembalian = '';
  TextEditingController _dateController1 = TextEditingController();
  TextEditingController _dateController2 = TextEditingController();
  List<dynamic> historylist = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    fetchdata();
  }

  @override
  void dispose() {
    _dateController1.dispose();
    _dateController2.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('dropdownValueHistory', dropdownValue);
    prefs.setString('date1', _dateController1.text);
    prefs.setString('date2', _dateController2.text);
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    String currentDate = DateFormat('dd-MM-yyyy').format(now);

    setState(() {
      dropdownValue = prefs.getString('dropdownValueHistory') ?? 'Penjualan';
      _dateController1.text = prefs.getString('date1') ?? currentDate;
      _dateController2.text = prefs.getString('date2') ?? currentDate;
    });
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

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  bool isLoading = false;
  Future<void> fetchdata() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    List<String>? dataLocal = prefs.getStringList('local_permanent');

    String date1Formatted = DateFormat('yyyy-MM-dd').format(
      DateFormat('dd-MM-yyyy').parse(_dateController1.text),
    );
    String date2Formatted = DateFormat('yyyy-MM-dd').format(
      DateFormat('dd-MM-yyyy').parse(_dateController2.text),
    );
    String kategori;
    if (dropdownValue == 'Pembelian') {
      kategori = 'Pengeluaran';
    } else if (dropdownValue == 'Penjualan') {
      kategori = 'Pemasukan';
    } else {
      kategori =
          dropdownValue;
    }
    bool isConnected = await _checkInternetConnection();
    print('Internet connected: $isConnected');

    if (isConnected) {
      try {
        final response = await http.get(
          Uri.parse(
            'https://flea-vast-sadly.ngrok-free.app/api/getransaksi?tanggal_awal=$date1Formatted&tanggal_akhir=$date2Formatted&kategori=$kategori',
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);

          if (data is Map<String, dynamic> && data.containsKey('data')) {
            var listData = data['data'];
            if (listData is List) {
              print("Data from API: $listData");

              setState(() {
                historylist = listData.where((item) => item != null).toList();
                isLoading = false;
              });
            } else {
              print(
                  'Expected a List under key "data" but got: ${listData.runtimeType}');
              setState(() {
                historylist = [];
                isLoading = false;
              });
            }
          } else {
            print(
                'Expected a Map with key "data" but got: ${data.runtimeType}');
            setState(() {
              historylist = [];
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
        print('Error fetching data: $error');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (dataLocal != null && dataLocal.isNotEmpty) {
        try {
          List<Map<String, dynamic>> localTransactions = [];

          for (var transactionJson in dataLocal) {
            try {
              var decoded = jsonDecode(transactionJson);
              if (decoded is Map<String, dynamic>) {
                localTransactions.add(decoded);
              } else {
                print('Skipped invalid JSON data: $transactionJson');
              }
            } catch (e) {
              print('Error decoding JSON: $transactionJson - $e');
            }
          }

          print('Local transactions before filtering: $localTransactions');

          List<Map<String, dynamic>> filteredLocalTransactions =
              localTransactions.where((transaction) {
            String transactionDate =
                transaction['tanggal_transaksi'].substring(0, 10);
            bool dateInRange = transactionDate.compareTo(date1Formatted) >= 0 &&
                transactionDate.compareTo(date2Formatted) <= 0;
            bool categoryMatches = kategori == null ||
                transaction['kategori'].toLowerCase() ==
                    kategori.toLowerCase();

            print("Transaction date: $transactionDate");
            print("Date in range: $dateInRange");
            print("Category matches: $categoryMatches");

            return dateInRange && categoryMatches;
          }).toList();

          print('Filtered local transactions: $filteredLocalTransactions');

          setState(() {
            historylist = filteredLocalTransactions;
            isLoading = false;
          });
        } catch (e) {
          print("Error processing local transactions: $e");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          historylist = [];
        });
      }
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
                      "HISTORY",
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
                      indent: 1,
                      endIndent: 1,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
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
                                    _savePreferences();
                                  });
                                },
                                items: <String>[
                                  'Penjualan',
                                  'Pembelian'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Center(child: Text(value)),
                                  );
                                }).toList(),
                                dropdownColor:
                                    Color.fromARGB(255, 255, 255, 255),
                                menuMaxHeight: 200,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
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
                                    hintStyle: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Color(0xff000000),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xffffffff),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(
                                          color: Color(0xff000000), width: 0.3),
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
                                    hintStyle: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Color(0xff000000),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xffffffff),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(
                                          color: Color(0xff000000), width: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
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
                        child: isLoading
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 350),
                                child: SpinKitThreeBounce(
                                  color: Color(0xff2dbcf1),
                                  size: 25.0,
                                ),
                              )
                            : historylist.isEmpty
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                    child: Text(
                                      "Tidak ada data",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 18,
                                        color: Color(0xff000000),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.vertical,
                                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                                    itemCount: historylist.length,
                                    itemBuilder: (context, index) {
                                      final transaction = historylist[index];

                                      if (transaction == null ||
                                          transaction['items'] == null) {
                                        return SizedBox.shrink();
                                      }

                                      final currencyFormat =
                                          NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: '',
                                              decimalDigits: 0);

                                      String tanggalTransaksi =
                                          transaction['tanggal_transaksi'];
                                      String formattedDate =
                                          tanggalTransaksi.replaceAll('T', ' ');

                                      // Parse and format values safely
                                      int totalHarga = int.tryParse(
                                              transaction['total_harga']
                                                  .toString()
                                                  .replaceAll('.', '')) ??
                                          0;
                                      int potongan = int.tryParse(
                                              transaction['potongan']
                                                  .toString()
                                                  .replaceAll('.', '')) ??
                                          0;
                                      int jumlahDibayar = int.tryParse(
                                              transaction['jumlah_dibayar']
                                                  .toString()
                                                  .replaceAll('.', '')) ??
                                          0;
                                      int kembalian = int.tryParse(
                                              transaction['kembalian']
                                                  .toString()
                                                  .replaceAll('.', '')) ??
                                          0;

                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 10),
                                        child: Container(
                                          alignment: Alignment.topCenter,
                                          margin: EdgeInsets.all(0),
                                          padding: EdgeInsets.all(0),
                                          width: 200,
                                          decoration: BoxDecoration(
                                            color: Color(0x00000000),
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.zero,
                                            border: Border.all(
                                              color: Color(0xb19e9e9e),
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsets.fromLTRB(0, 5, 0, 0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Text(
                                                      "${transaction['kode_transaksi']}",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 14,
                                                        color:
                                                            Color(0xff000000),
                                                      ),
                                                    ),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 14,
                                                        color:
                                                            Color(0xff000000),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 10),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 0, 15, 0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ...transaction['items']
                                                          .asMap()
                                                          .entries
                                                          .map<Widget>((entry) {
                                                        int itemIndex =
                                                            entry.key + 1;
                                                        var item = entry.value;

                                                        int jumlah =
                                                            int.tryParse(item[
                                                                        'jumlah']
                                                                    .toString()) ??
                                                                0;
                                                        int hargaSatuan =
                                                            int.tryParse(item[
                                                                        'harga_satuan']
                                                                    .toString()
                                                                    .replaceAll(
                                                                        '.',
                                                                        '')) ??
                                                                0;
                                                        int totalHargaItem =
                                                            jumlah *
                                                                hargaSatuan;

                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 10.0),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "$itemIndex. ${item['nama_barang']}",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                      0xff000000),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .fromLTRB(
                                                                        15,
                                                                        0,
                                                                        0,
                                                                        0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                      "${currencyFormat.format(jumlah)} x ${currencyFormat.format(hargaSatuan)}",
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        fontSize:
                                                                            13,
                                                                        color: Color(
                                                                            0xff000000),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      "${currencyFormat.format(totalHargaItem)}",
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        fontSize:
                                                                            13,
                                                                        color: Color(
                                                                            0xff000000),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          12, 0, 12, 10),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "Total Harga",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                          Text(
                                                            "Potongan",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                          Text(
                                                            "Dibayar",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                          Text(
                                                            "Kembalian",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            "${currencyFormat.format(totalHarga)}",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                          Text(
                                                            "${currencyFormat.format(potongan)}",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                          Text(
                                                            "${currencyFormat.format(jumlahDibayar)}",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                          Text(
                                                            "${currencyFormat.format(kembalian)}",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xff000000),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
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
