import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dpos/component/Appbar.dart';
import 'package:dpos/page/homepage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KonfirmasiPage extends StatefulWidget {
  final List<String> namaBarang;
  final List<String> jumlahbarang;
  final List<String> hargaSatuan;
  final List<String>? harga_pokok;
  final List<String>? harga_jual;
  final List<String> hargaTotal;
  final List<int?> idbarang;
  final String Kategori;
  final String potongan;
  final String bayar;
  final String date;
  final String kodetransaksi;
  final String? totalall;
  final String? kembalian;
  final bool opsiprint;

  KonfirmasiPage({
    Key? key,
    required this.namaBarang,
    required this.jumlahbarang,
    required this.hargaSatuan,
    required this.hargaTotal,
    required this.totalall,
    required this.Kategori,
    required this.potongan,
    required this.bayar,
    required this.kembalian,
    required this.date,
    required this.idbarang,
    required this.opsiprint,
    required this.kodetransaksi,
    this.harga_pokok,
    this.harga_jual,
  }) : super(key: key);

  @override
  State<KonfirmasiPage> createState() => _KonfirmasiPageState();
}

class _KonfirmasiPageState extends State<KonfirmasiPage> {
  String store = "";
  String phone = "";
  String? selectedDeviceAddress;
  bool isConnected = false;
  bool isOnline = true;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<String> localTransactions = [];

  @override
  void initState() {
    super.initState();
    loadSelectedDevice();
    print(widget.namaBarang);
    print(widget.idbarang);
    print(widget.idbarang);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> postTransaction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> localTransactions =
        prefs.getStringList('local_transactions') ?? [];
    print("local: ${localTransactions}");

    List<String> localPermanent = prefs.getStringList('local_permanent') ?? [];
    bool isOnline = await _checkInternetConnection();

    List<Map<String, dynamic>> items = [];
    List<Map<String, dynamic>> databarang = [];
    for (int i = 0; i < widget.namaBarang.length; i++) {
      final barangId = widget.idbarang[i];
      if (barangId == 0 || barangId.toString().isEmpty) {
        databarang.add({
          'id': barangId.toString(),
          'nama_barang': widget.namaBarang[i],
          'harga_jual': widget.harga_jual?[i] != null
              ? widget.harga_jual![i].toString()
              : '',
          'harga_pokok': widget.harga_pokok?[i] != null
              ? widget.harga_pokok![i].toString()
              : '',
        });
      }

      items.add({
        'jumlah':
            (int.tryParse(widget.jumlahbarang[i].replaceAll('.', ''))) ?? 0,
        'harga_satuan':
            (int.tryParse(widget.hargaSatuan[i].replaceAll('.', '')) ?? 0)
                .toString(),
        // 'harga_pokok': int.tryParse(widget.harga_pokok![i].replaceAll('.', ''))
        //         ?.toString() ??
        //     '',
        'harga_pokok': widget.harga_pokok != null &&
                widget.harga_pokok!.length > i &&
                widget.harga_pokok![i] != null
            ? int.tryParse(widget.harga_pokok![i].replaceAll('.', ''))
                    ?.toString() ??
                ''
            : '',

        'harga_jual': widget.harga_jual != null &&
                widget.harga_jual!.length > i &&
                widget.harga_jual![i] != null
            ? int.tryParse(widget.harga_jual![i].replaceAll('.', ''))
                    ?.toString() ??
                ''
            : '',

        'total_harga':
            (int.tryParse(widget.hargaTotal[i].replaceAll('.', '')) ?? 0)
                .toString(),
        'barang_id': barangId == 0 ? "" : barangId.toString(),
        'nama_barang': widget.namaBarang[i],
      });
    }

    if (databarang.isNotEmpty) {
      String existingDatabarang = prefs.getString('databarang') ?? '[]';
      List<dynamic> decodedExistingDatabarang;

      try {
        decodedExistingDatabarang =
            jsonDecode(existingDatabarang) as List<dynamic>;
      } catch (e) {
        print('Error decoding existing databarang: $e');
        decodedExistingDatabarang = [];
      }

      Map<String, Map<String, dynamic>> existingDatabarangMap = {
        for (var item in decodedExistingDatabarang)
          (item['id'].toString()): item
      };

      for (var item in databarang) {
        if (!existingDatabarangMap.containsKey(item['id'].toString())) {
          decodedExistingDatabarang.add(item);
        }
      }

      String updatedDatabarang = jsonEncode(decodedExistingDatabarang);
      await prefs.setString('databarang', updatedDatabarang);
    }

    final currentTransactionDataLocal = {
      'kode_transaksi': widget.kodetransaksi.toString(),
      'tanggal_transaksi': widget.date.toString(),
      'total_harga': widget.totalall.toString(),
      'potongan': widget.potongan.toString(),
      'jumlah_dibayar': widget.bayar.toString(),
      'kembalian': widget.kembalian.toString(),
      'kategori': widget.Kategori.toString(),
      'items': items,
    };

    final currentTransactionDataAPI = {
      'kode_transaksi': widget.kodetransaksi.toString(),
      'tanggal_transaksi': widget.date.toString(),
      'total_harga':
          (int.tryParse(widget.totalall!.replaceAll('.', '')) ?? 0).toString(),
      'potongan':
          (int.tryParse(widget.potongan.replaceAll('.', '')) ?? 0).toString(),
      'jumlah_dibayar': (int.tryParse(widget.bayar.replaceAll('.', '')) ?? 0),
      'kembalian':
          (int.tryParse(widget.kembalian!.replaceAll('.', '')) ?? 0).toString(),
      'kategori': widget.Kategori.toString(),
      'items': items,
    };

    print("status koneksi: ${isOnline}");
    print("data sekarang : ${jsonEncode(currentTransactionDataLocal)}");

    if (!isOnline) {
      localTransactions.add(jsonEncode(currentTransactionDataAPI));
      await prefs.setStringList('local_transactions', localTransactions);

      localPermanent.add(jsonEncode(currentTransactionDataLocal));
      await prefs.setStringList('local_permanent', localPermanent);
      print('Transaction saved locally in offline mode');
    } else {
      localPermanent.add(jsonEncode(currentTransactionDataLocal));
      await prefs.setStringList('local_permanent', localPermanent);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Center(
            child: CircularProgressIndicator(
          color: Color(0xff20c0fa),
        )),
      );

      await syncLocalTransactions(currentTransactionDataAPI);

      Navigator.of(context).pop();
    }

    await showSuccessPopupAndNavigate();
  }

  Future<void> syncLocalTransactions(
      Map<String, dynamic> currentTransactionDataAPI) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> localTransactions =
        prefs.getStringList('local_transactions') ?? [];

    List<Map<String, dynamic>> transactions = localTransactions
        .map((txn) => jsonDecode(txn) as Map<String, dynamic>)
        .toList();

    final transactionCode = currentTransactionDataAPI['kode_transaksi'];
    if (transactions.every((txn) => txn['kode_transaksi'] != transactionCode)) {
      transactions.add(currentTransactionDataAPI);
    }

    final dataToSend = {'transactions': transactions};
    print(jsonEncode(dataToSend));

    try {
      await postTransactionToAPI(jsonEncode(dataToSend));
      print('Local transactions successfully synced and cleared.');
      await prefs.remove('local_transactions');
    } catch (e) {
      print('Error syncing transactions: $e');
    }
  }

  Future<void> postTransactionToAPI(String transactionsAsString) async {
    final sanitizedString = transactionsAsString.replaceAll(RegExp(r'\.'), '');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("Send to Api: ${sanitizedString}");
    final url = 'https://flea-vast-sadly.ngrok-free.app/api/transaksi';
    final headers = {
      'accept': "application/json",
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: sanitizedString,
      );

      if (response.statusCode == 201) {
        print('Transaction sent to API successfully.');
      } else {
        print(
            'Failed to send transaction. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to post transaction');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw e;
    }
  }

  void loadSelectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      store = prefs.getString('store') ?? "STORE";
      phone = prefs.getString('phone') ?? "0812345678";
    });
    selectedDeviceAddress = prefs.getString('selectedDeviceAddress');
    if (selectedDeviceAddress != null) {
      print("Selected device address: $selectedDeviceAddress");
      connectToDevice();
    }
  }

  void showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 4.0,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff20c0fa)),
              ),
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  Future<void> showSuccessPopupAndNavigate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Data berhasil dikirim!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
    );
  }

  void hideLoadingDialog() {
    Navigator.of(context).pop();
  }

  Future<void> connectToDevice() async {
    showLoadingDialog('Menghubungkan ke perangkat...');

    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      BluetoothDevice? selectedDevice = devices.firstWhere(
        (device) => device.address == selectedDeviceAddress,
      );

      if (selectedDevice != null) {
        print("Attempting to connect to device: ${selectedDevice.address}");
        bool? isCurrentlyConnected = await printer.isConnected;
        if (isCurrentlyConnected != null && isCurrentlyConnected) {
          await printer.disconnect();
          setState(() {
            isConnected = false;
          });
          print("Disconnected from previously connected device.");
        }

        await printer.connect(selectedDevice);
        setState(() {
          isConnected = true;
        });
        print("Connected to device: ${selectedDevice.address}");
        hideLoadingDialog();
      } else {
        hideLoadingDialog();
        showErrorDialog(
          'Printer tidak ditemukan. Periksa pengaturan dan pastikan Printer aktif atau tetap kirim data?',
        );
      }
    } catch (e) {
      print('Error connecting to device: $e');
      hideLoadingDialog();
      showErrorDialog(
        'Gagal terhubung ke Printer. Periksa pengaturan atau pastikan Printer dalam keadaan ON. atau tetap kirim data?',
      );
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Koneksi Gagal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Homepage()),
                );
              },
            ),
            TextButton(
              child: Text(
                'Tetap kirim',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
              ),
              onPressed: () {
                postTransaction();

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> printStruk() async {
    showLoadingDialog('Sedang mencetak...');

    if (!isConnected) {
      await connectToDevice();
    }

    if (isConnected) {
      print("Starting print job");
      try {
        printer.printCustom(store, 2, 1);
        printer.printCustom(phone, 1, 1);
        printer.printNewLine();
        printer.printCustom(
            "${widget.kodetransaksi}        s     ${widget.date}", 0, 1);
        printer.printCustom("--------------------------------", 1, 1);
        for (int i = 0; i < widget.namaBarang.length; i++) {
          printer.printLeftRight("${i + 1}. ${widget.namaBarang[i]}", "", 1);
          printer.printLeftRight(
              "   ${widget.jumlahbarang[i]} x @${widget.hargaSatuan[i]}",
              widget.hargaTotal[i],
              1);
        }
        printer.printCustom("--------------------------------", 1, 1);
        printer.printLeftRight("total", "${widget.totalall}", 1);
        printer.printLeftRight("potongan", "${widget.potongan}", 1);
        printer.printLeftRight("bayar", "${widget.bayar}", 1);
        printer.printLeftRight("kembalian", "${widget.kembalian}", 1);
        printer.printCustom("", 0, 0);
        printer.printCustom("Terimakasih", 2, 1);
        printer.paperCut();

        await postTransaction();
      } catch (e) {
        print('Error printing receipt: $e');
        await connectToDevice();
      } finally {
        hideLoadingDialog();
      }
    } else {
      print("Printer not connected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        store,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Color(0xff000000),
                        ),
                      ),
                      Text(
                        phone,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: Color(0xff000000),
                        ),
                      ),
                      Divider(
                        color: Color(0xff464646),
                        height: 16,
                        thickness: 1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            widget.kodetransaksi,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xff000000),
                            ),
                          ),
                          Text(
                            widget.date,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xff000000),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: widget.namaBarang.length,
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                                child: Text(
                                  (index + 1).toString(),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xff000000),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                widget.namaBarang[index],
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Color(0xff000000),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(37, 0, 0, 0),
                                child: Text(
                                  "${widget.jumlahbarang[index]} x @${widget.hargaSatuan[index]}", // Jumlah x Harga satuan
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xff000000),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                                child: Text(
                                  widget.hargaTotal[index],
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xff000000),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Color(0xff464646),
            height: 16,
            thickness: 1,
            indent: 12,
            endIndent: 12,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(14, 5, 14, 14),
            color: Color(0xffffffff),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                    Text(
                      "${widget.totalall}",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Potongan",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                    Text(
                      "${widget.potongan}",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Bayar",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                    Text(
                      "${widget.bayar}",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kembalian",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                    Text(
                      "${widget.kembalian}",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff000000),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              MaterialButton(
                onPressed: () async {
                  if (widget.opsiprint == true) {
                    await printStruk();
                  } else {
                    await postTransaction();
                  }
                },
                color: Color(0xff20c0fa),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  "Selesai",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textColor: Color(0xff000000),
                height: 50,
                minWidth: MediaQuery.of(context).size.width,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
