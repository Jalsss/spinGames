part of 'indicators.dart';

class TriangleIndicator extends StatelessWidget {
  final Color? color;

  const TriangleIndicator({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Transform.rotate(
      angle: 3.15,
      child: Transform.translate(offset: const Offset(0.0,30.0), child: new Image.asset("beer-bottle.png",height: 60),
    ));
  }
}
