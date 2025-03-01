import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../draw/models/stroke.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<List<Stroke>> _drawingBox;
  @override
  void initState() {
    _initializeHive();
    super.initState();
  }

  Future<void>_initializeHive() async{
    _drawingBox = Hive.box<List<Stroke>>('drawings');
  }

  @override
  Widget build(BuildContext context) {
    final drawingNames = _drawingBox.keys.cast<String>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawings'),
      ),
      body: drawingNames.isEmpty
          ? const Center(child: Text('No drawings yet'),)
          :
      GridView.builder(
          padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
          ),
          itemCount: drawingNames.length,
          itemBuilder: (context, index){
            final name = drawingNames[index];
            return GestureDetector(
              onTap: (){
                Navigator.pushNamed(
                    context,
                    '/draw',
                  arguments: name
                );
              },
              child: Card(
                elevation: 4,
                child: Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.draw),
        onPressed: (){
          Navigator.pushNamed(context, '/draw');
        },
      )
    );
  }
}
