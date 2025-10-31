part of '../../single_pagination/pagination.dart';

class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({super.key, required this.exception});

  final Exception exception;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Error occurred: $exception'));
  }
}
