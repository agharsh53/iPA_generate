import 'dart:convert';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_picker/language_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:money_tracker/common/widgets/settings_items.dart';
import 'package:money_tracker/repository/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/color/colors.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';


class SetttingsScreen extends StatefulWidget {
  const SetttingsScreen({super.key});

  @override
  State<SetttingsScreen> createState() => _SetttingsScreenState();
}


class _SetttingsScreenState extends State<SetttingsScreen> {
  String? username;
  String? email;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'INR';
  bool loading = true;


  Future<void> logout(BuildContext context) async {
    await supabase.auth.signOut();
    if(!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
    _loadSelectedCurrency();
    _loadSelectedLanguage();
  }

  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null){
      print('User not found');
      return;
    }

    final response = await supabase
        .from('profiles')
        .select('name, email')
        .eq('id', user.id)
        .single();

    setState(() {
      username = response['name'];
      email = response['email'];
      loading = false;
    });
  }

  Future<void> _loadSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrency = prefs.getString('selectedCurrency');
    setState(() {
      _selectedCurrency = storedCurrency ?? 'INR';
    });
  }
  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString('selectedLanguage');
    setState(() {
      _selectedLanguage = storedLanguage ?? 'English';// Default to current month if null
    });
  }

  Future<void> _saveSelectedCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);
  }
  Future<void> _saveSelectedLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  @override
  Widget build(BuildContext context) {

    double remainingHeight = MediaQuery.of(context).size.height * 0.77;
    return Scaffold(
      backgroundColor: Colors.white12,
      body: Stack(
        children: <Widget>[
          // Top Purple Section (Constant)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Coloors.blueLight,
                  Coloors.blueDark,
                  Coloors.blueLight2
                ],
                begin: FractionalOffset(0.5, 0.6),
                end: FractionalOffset(0.0, 0.5),
                stops: [0.0,0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Coloors.backgroundLight,
                      ),
                    ),
                    TextButton(onPressed:()=>logout(context), child: const Text('Logout', style: TextStyle(fontSize: 25,color: Coloors.backgroundLight),))
                  ],
                ),


                const SizedBox(height: 20),
              ],
            ),
          ),
    Positioned(
    top: MediaQuery.of(context).size.height * 0.15,
    left: 0,
    right: 0,
    bottom: 0,
    child: SingleChildScrollView(
    child: Container(
    decoration: const BoxDecoration(
    color: Coloors.backgroundLight,
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    child: Padding(
    padding: const EdgeInsets.all(22.0),
    child:
    SizedBox(
    height: remainingHeight - 44, // Subtract padding
    child: ListView(
              children: <Widget>[
                SettingsItems(icon : Icons.language,label:  'Language',value:  _selectedLanguage ,check: true,onTap:  () {
                    _showSelectedLanguage();

                  print('User selected the language');

                }),
                SettingsItems(icon:Icons.attach_money, label:  'Currency',value:  _selectedCurrency ,check: true,onTap: () {

                    _showCurrencyPicker();
                }),
                SettingsItems(icon:Icons.star, label:  'Rate', value: '',check:  false,onTap:  () {
                  // Handle Rate action
                }),
                SettingsItems(icon:Icons.share,label:  'Share',value:  '',check:  false,onTap:  () {
                  // Handle Share action
                }),
                SettingsItems(icon: Icons.security,label:  'Privacy Policy',value:  '',check: false,onTap:  () {
                  // Handle Privacy Policy action
                }),
                SettingsItems(icon:Icons.person,label:  'User Details',value:  '',check: false,onTap:()=> loading? Center(child: CircularProgressIndicator()):_showUserDetailsModal(),
                ),
              ],
            )
    ),


    ),
    ),
    ),
    ),
        ],
      ),
    );
  }

 void _showSelectedLanguage(){
    showDialog(
      context: context,
      builder:(context)
    {
      return LanguagePickerDialog(

        title: const Text('Select Your Language'),
        isSearchable: true,
        searchInputDecoration: const InputDecoration(hintText: 'Search'),
        onValuePicked: (Language language) {
          setState(() {
            _selectedLanguage = language.name;
            _saveSelectedLanguage(_selectedLanguage);
          });
        },

      );

      },
    );
    }

  void _showCurrencyPicker(){
    showCurrencyPicker(context: context,showFlag: true,
        showCurrencyName: true,
        showCurrencyCode: true,
        onSelect: (Currency currency){
      setState(() {
        _selectedCurrency = currency.code;
        _saveSelectedCurrency(_selectedCurrency);
      });
        },
        favorite: <String>['INR','MYD','USD'],
        theme: CurrencyPickerThemeData(
          flagSize: 25,
          titleTextStyle: const TextStyle(fontSize: 18),
          subtitleTextStyle: const TextStyle(fontSize: 15),
          bottomSheetHeight: MediaQuery.of(context).size.height*0.8,
        )
    );
  }
  void _showUserDetailsModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
            CircleAvatar(
            radius: 50.0,
            backgroundImage: const AssetImage('assets/images/harsh_resume.jpg'),
          ),
              const SizedBox(height: 16.0),
              Text(username!, style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Text(email!),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
