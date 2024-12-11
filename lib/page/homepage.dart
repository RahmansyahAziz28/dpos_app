import 'package:dpos/component/Appbar.dart';
import 'package:dpos/page/history.dart';
import 'package:dpos/page/laporan.dart';
import 'package:dpos/page/pemasukan.dart';
import 'package:dpos/page/pengeluaran.dart';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  BlueThermalPrinter printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermission();
  }

  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.status;
    if (!status.isGranted) {
      await Permission.bluetooth.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: CustomAppBar(),
      body: Align(
        alignment: Alignment(0.0, 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PemasukanPage()),
                  );
                },
                color: Color(0xff20c0fa),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  "Penjualan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                textColor: Color(0xff000000),
                height: 60,
                minWidth: 160,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PengeluaranPage()),
                  );
                },
                color: Color(0xff20c0fa),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff808080), width: 0),
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  "Pembelian",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                textColor: Color(0xff000000),
                height: 60,
                minWidth: 160,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LaporanPage()),
                  );
                },
                color: Color(0xff20c0fa),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff808080), width: 0),
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  "Laporan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                textColor: Color(0xff000000),
                height: 60,
                minWidth: 160,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryPage()),
                  );
                },
                color: Color(0xff20c0fa),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff808080), width: 0),
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  "History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                textColor: Color(0xff000000),
                height: 60,
                minWidth: 160,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
