// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, sort_child_properties_last
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:dpos/page/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:dpos/component/Appbar.dart';
import 'package:collection/collection.dart';

class PrinterManager {
  static final PrinterManager _instance = PrinterManager._internal();

  factory PrinterManager() {
    return _instance;
  }

  PrinterManager._internal();

  BlueThermalPrinter printer = BlueThermalPrinter.instance;

  bool isConnected = false;
  BluetoothDevice? selectedDevice;

  Future<void> connectToDevice(
      BluetoothDevice device, StateSetter setState) async {
    if (device != null) {
      try {
        if (isConnected) {
          await printer.disconnect(); // Disconnect if already connected
          isConnected = false;
        }
        await printer.connect(device);
        saveConnectionStatus(true);
        isConnected = true;
        selectedDevice = device;
        setState(() {
          selectedDevice = device;
        });
      } catch (e) {
        print("Connection error: $e");
        // Handle the connection error here, maybe show a message to the user
      }
    } else {
      print("No device selected");
    }
  }

  Future<void> disconnectFromDevice() async {
    if (!isConnected) return;
    await printer.disconnect();
    saveConnectionStatus(false);
    isConnected = false;
  }

  Future<void> saveConnectionStatus(bool isConnected) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isPrinterConnected', isConnected);
  }

  Future<bool> getConnectionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isPrinterConnected') ?? false;
  }

  Future<void> printDemoReceipt() async {
    if (selectedDevice != null && isConnected) {
      try {
        await printer.printCustom("Test Print", 1, 1);
      } catch (e) {
        print("Printing error: $e");
      }
    } else {
      print("Printer not connected or device not selected");
    }
  }
}

Future<void> _saveSelectedDevice(BluetoothDevice? device) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (device != null) {
    await prefs.setString('selectedDevice', device.name ?? '');
    await prefs.setString('selectedDeviceAddress', device.address ?? '');
  } else {
    await prefs.remove('selectedDevice');
  }
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late TextEditingController _StoreController;
  late TextEditingController _phoneController;
  bool isConnected = false;
  BluetoothDevice? selectedDevices;

  PrinterManager _printerManager = PrinterManager();

  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();
    _StoreController = TextEditingController();
    _phoneController = TextEditingController();
    _loadBluetoothDevices();
    _loadPreferences().then((_) {
      _updateConnectionStatus();
    });
  }

  Future<void> _updateConnectionStatus() async {
    bool connectionStatus = await _printerManager.getConnectionStatus();
    setState(() {
      isConnected = connectionStatus;
    });
  }

  Future<void> _loadBluetoothDevices() async {
    List<BluetoothDevice> availableDevices =
        await _printerManager.printer.getBondedDevices();
    setState(() {
      devices = availableDevices;
    });
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _StoreController.text = prefs.getString('store') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';

      String? selectedDeviceName = prefs.getString('selectedDevice');
      if (selectedDeviceName != null && selectedDeviceName.isNotEmpty) {
        BluetoothDevice? device = devices
            .firstWhereOrNull((device) => device.name == selectedDeviceName);
        if (device != null) {
          selectedDevices = device;
          _printerManager.connectToDevice(device, setState);
        }
      }
    });
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('store', _StoreController.text);
    await prefs.setString('phone', _phoneController.text);
    await _saveSelectedDevice(selectedDevices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xffffffff),
      appBar: CustomAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(height: 10),
                    Text(
                      "SETTING",
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Expanded(
                          // flex: 1,
                          // child:
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 40, 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SizedBox(height: 10),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 15),
                                  child: Text(
                                    "STORE",
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15,
                                      color: Color(0xff000000),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Text(
                                    "Phone",
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15,
                                      color: Color(0xff000000),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 13),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: Text(
                                    "Printer",
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15,
                                      color: Color(0xff000000),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SizedBox(height: 4),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0),
                                      border: Border.all(
                                        color: Color(0xff000000),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _StoreController,
                                      obscureText: false,
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 14,
                                        color: Color(0xff000000),
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Color(0xff000000),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _phoneController,
                                      obscureText: false,
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 14,
                                        color: Color(0xff000000),
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButton<BluetoothDevice>(
                                          isExpanded: true,
                                          value: selectedDevices,
                                          hint: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                12, 0, 0, 0),
                                            child: Text(
                                              'Pilih Printer',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                                fontSize: 14,
                                                color: Color(0xff6c757d),
                                              ),
                                            ),
                                          ),
                                          onChanged: (device) {
                                            setState(() {
                                              selectedDevices = device;
                                              _printerManager.connectToDevice(
                                                  device!, setState);
                                            });
                                          },
                                          items: devices
                                              .map((e) => DropdownMenuItem(
                                                    child: Text(
                                                      e.name!,
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    value: e,
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.refresh),
                                        onPressed: () async {
                                          await _loadBluetoothDevices(); // Refresh devices list
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Bluetooth devices refreshed!'),
                                            ),
                                          );
                                        },
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
                    SizedBox(height: 5),
                    MaterialButton(
                      onPressed: () {
                        _printerManager.printDemoReceipt();
                      },
                      color: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.print,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Test Print",
                            style: TextStyle(
                              fontFamily: 'poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      height: 40,
                      minWidth: 140,
                    ),
                    SizedBox(height: 10),
                    MaterialButton(
                      onPressed: () async {
                        await _savePreferences();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Data telah disimpan!'),
                            duration: Duration(seconds: 2),
                            action: SnackBarAction(
                              textColor: Colors.white,
                              label: 'OK',
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        );
                      },
                      color: Color(0xff20c0fa),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Simpan",
                            style: TextStyle(
                              fontFamily: 'poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      height: 40,
                      minWidth: 140,
                    )
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                "Version 1.00",
                textAlign: TextAlign.start,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 13,
                  color: Color(0xff000000),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
