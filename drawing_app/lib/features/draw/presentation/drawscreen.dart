import 'package:drawing_app/features/draw/models/stroke.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.deepPurple;
  double _brushSize = 4.0;
  late Box<List<Stroke>> _drawingBox;
  String? _drawingName;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      _initializeHive();
    });
    super.initState();
  }

  Future<void> _initializeHive() async{
    _drawingBox = Hive.box('drawings');

    final name = ModalRoute.of(context)?.settings.arguments as String?;
    if(name != null){
      setState(() {
        _drawingName = name;
        _strokes = _drawingBox.get(name) ?? [];
      });
    }
  }

  Future<void> _saveDrawing(String name) async {
    await _drawingBox.put(name, _strokes);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drawing $name saved'),)
    );
  }

void _showSaveDialog(){
    final TextEditingController _controller = TextEditingController();
    showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: const Text('Save Drawing'),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Drawing Name'),
          ),
          actions: [
            TextButton(
                onPressed: (){
                Navigator.of(context).pop();
              }, child: Text('Cancel')
            ),
            TextButton(
                onPressed: (){
                  final name = _controller.text.trim();
                  if(name.isNotEmpty){
                    setState(() {
                      _drawingName = name;
                    });
                    _saveDrawing(name);
                    Navigator.of(context).pop();
                  }
                }, child: Text('Save')
            ),
          ],
          );
        }
    );
}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_drawingName ?? "Draw your Imaginations")
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details){
                setState(() {
                  _currentPoints.add(details.localPosition);
                });
              },
              onPanUpdate: (details){
                setState(() {
                  _currentPoints.add(details.localPosition);
                });
              },
              onPanEnd: (details){
                setState(() {
                  _strokes.add(
                    Stroke.fromOffsets(
                        points: List.from(_currentPoints),
                        color: _selectedColor,
                        brushSize: _brushSize
                    ),
                  );
                  _currentPoints = [];
                  _redoStokes = [];
                });
              },
              child: CustomPaint(
                painter: DrawPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColor,
                  currentBrushSize: _brushSize
                ),
                size: Size.infinite,
              ),
            ),
          ),
            _buildColorBar(),
            _buildToolBar(),

        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _showSaveDialog,
          child: const Icon(Icons.save),),
    );
  }

  Widget _buildToolBar(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //undo Button
          IconButton(
              onPressed: _strokes.isNotEmpty ? (){
                setState(() {
                  _redoStokes.add(_strokes.removeLast());
                });
              } : null,
              icon: const Icon(Icons.undo)
          )

            // Brush Size dropdown
            ,DropdownButton(
                value: _brushSize,
                items: [
                  DropdownMenuItem(
                    value: 1.0,
                    child: Text('Very Small'),
                  ),
                  DropdownMenuItem(
                    value: 2.0,
                    child: Text('Small'),
                  ),
                  DropdownMenuItem(
                    value: 4.0,
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: 8.0,
                    child: Text('Large'),
                  ),
                ],
                onChanged: (value){
                  setState(() {
                    _brushSize = value!;
                  });
                }
            ),
          //redo Button
          IconButton(
              onPressed: _redoStokes.isNotEmpty ? (){
                setState(() {
                  _strokes.add(_redoStokes.removeLast());
                });
              } : null,
              icon: const Icon(Icons.redo)
          ),

        ],
      ),
    );
  }
  Widget _buildColorBar(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //Color Picker
          Row(
            children: [
              _buildColorButton(Colors.black),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.brown),
              _buildColorButton(Colors.yellow),
              _buildColorButton(Colors.green),
              _buildColorButton(Colors.greenAccent),
              _buildColorButton(Colors.pink),
              _buildColorButton(Colors.purple),
              _buildColorButton(Colors.orange),
              _buildColorButton(Colors.cyan),
              _buildColorButton(Colors.indigo),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color){
    return GestureDetector(
      onTap: (){
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.transparent : Colors.black,
            width: 2
          )
        ),
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentBrushSize;

  DrawPainter({super.repaint, required this.strokes, required this.currentPoints, required this.currentColor, required this.currentBrushSize});

  @override
  void paint(Canvas canvas, Size size) {
    for(final stroke in strokes){
      final paint = Paint()
        ..color = stroke.strokeColor
        ..strokeWidth = stroke.brushSize
        ..strokeCap = StrokeCap.round;

      final points = stroke.offsetPoints;
      for(int i = 0; i < stroke.points.length - 1; i++){
        if(points[i] != Offset.zero && points[i + 1] != Offset.zero){
          canvas.drawLine(points[i], points[i + 1], paint);
        }
      }
    }

    final paint = Paint()
      ..color = currentColor
      ..strokeWidth = currentBrushSize
      ..strokeCap = StrokeCap.round;

    for(int i = 0; i < currentPoints.length - 1; i++){
      if(currentPoints[i] != Offset.zero && currentPoints[i + 1] != Offset.zero){
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
      }
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
   return true;
  }
}

