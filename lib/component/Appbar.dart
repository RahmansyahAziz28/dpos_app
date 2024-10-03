import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpos/page/history.dart';
import 'package:dpos/page/laporan.dart';
import 'package:dpos/page/pemasukan.dart';
import 'package:dpos/page/pengeluaran.dart';
import 'package:dpos/page/setting.dart';
import 'package:dpos/page/login.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function? removeSuggestionsOverlay;

  CustomAppBar({this.removeSuggestionsOverlay});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4,
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: Color(0xff20c0fa),
      shape: Border(
        bottom: BorderSide(
          color: Color(0xff000000),
          width: 2.0,
        ),
      ),
      title: Text(
        "dPOS",
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          fontSize: 30,
          color: Color(0xff000000),
        ),
      ),
      leading: GestureDetector(
        onTap: () {
          if (removeSuggestionsOverlay != null) {
            removeSuggestionsOverlay!();
          }
          showMenu<String>(
            context: context,
            color: Color(0xff20c0fa),
            position: RelativeRect.fromLTRB(0, kToolbarHeight + 35, 0, 0),
            items: [
              PopupMenuItem<String>(
                value: 'pemasukan',
                child: _buildPopupMenuItem('Penjualan'),
              ),
              PopupMenuItem<String>(
                value: 'pengeluaran',
                child: _buildPopupMenuItem('Pembelian'),
              ),
              PopupMenuItem<String>(
                value: 'laporan',
                child: _buildPopupMenuItem('Laporan'),
              ),
              PopupMenuItem<String>(
                value: 'history',
                child: _buildPopupMenuItem('History'),
              ),
              PopupMenuItem<String>(
                value: 'setting',
                child: _buildPopupMenuItem('Setting'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: _buildPopupMenuItem('Logout'),
              ),
            ],
          ).then((value) {
            if (value != null) {
              _handleMenuSelection(value, context);
            }
          });
        },
        child: Icon(
          Icons.menu,
          color: Color(0xff212435),
          size: 50,
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) async {
    if (value == 'logout') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SimpleLoginPage()),
        (route) => false,
      );
    } else {
      switch (value) {
        case 'pemasukan':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PemasukanPage()),
          );
          break;
        case 'pengeluaran':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PengeluaranPage()),
          );
          break;
        case 'laporan':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LaporanPage()),
          );
          break;
        case 'history':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HistoryPage()),
          );
          break;
        case 'setting':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingPage()),
          );
          break;
      }
    }
  }

  Widget _buildPopupMenuItem(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xff000000),
            width: 1.0,
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Text(
            "  $text ",
            style: TextStyle(
              color: Color(0xff000000),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
