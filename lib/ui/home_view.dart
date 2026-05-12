import 'package:flutter/material.dart';
import 'package:visorngin/models/screen_params.dart';
import 'package:visorngin/ui/detector_widget.dart';

/// [HomeView] stacks [DetectorWidget]
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      key: GlobalKey(),
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/visor_appbar.png',
          alignment: Alignment.topCenter,
          fit: BoxFit.contain,
        ),
      ),
      body: const DetectorWidget(),
    );
  }
}
