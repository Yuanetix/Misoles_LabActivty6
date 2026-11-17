import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final formKey = GlobalKey<FormState>();
  final firstController = TextEditingController();
  final secondController = TextEditingController();
  String resultText = 'Result: —';

  void calculate(String operator) {
    if (!formKey.currentState!.validate()) return;

    final num1 = double.parse(firstController.text.trim());
    final num2 = double.parse(secondController.text.trim());
    double computed;

    switch (operator) {
      case '+':
        computed = num1 + num2;
        break;
      case '-':
        computed = num1 - num2;
        break;
      case '×':
        computed = num1 * num2;
        break;
      case '÷':
        if (num2 == 0) {
          setState(() {
            resultText = 'Error: Cannot divide by zero.';
          });
          return;
        }
        computed = num1 / num2;
        break;
      default:
        return;
    }

    setState(() {
      resultText = 'Result: $computed';
    });
  }

  void clearFields() {
    firstController.clear();
    secondController.clear();
    formKey.currentState?.reset();
    setState(() {
      resultText = 'Result: —';
    });
  }

  String? validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a number.';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid numeric value.';
    }
    return null;
  }

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: firstController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'First Number',
                  border: OutlineInputBorder(),
                ),
                validator: validateNumber,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: secondController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Second Number',
                  border: OutlineInputBorder(),
                ),
                validator: validateNumber,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => calculate('+'),
                    child: const Text('+'),
                  ),
                  ElevatedButton(
                    onPressed: () => calculate('-'),
                    child: const Text('-'),
                  ),
                  ElevatedButton(
                    onPressed: () => calculate('×'),
                    child: const Text('×'),
                  ),
                  ElevatedButton(
                    onPressed: () => calculate('÷'),
                    child: const Text('÷'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    resultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: clearFields,
                icon: const Icon(Icons.refresh),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
