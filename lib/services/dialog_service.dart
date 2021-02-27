import 'dart:async';

class DialogService {
  void Function({String title, String label, String validationText})
      _showInputListener;

  void Function() _showShareDialogListener;

  Completer<String> _dialogCompleter;

  void registerInputDialogListener(
      void Function({String title, String label, String validationText})
          showDialogListener) {
    _showInputListener = showDialogListener;
  }

  void registerShareDialogListener(void Function() listener) {
    _showShareDialogListener = listener;
  }

  Future<String> getInput({String title, String label, String validationText}) {
    _dialogCompleter = Completer();
    _showInputListener(
        title: title, label: label, validationText: validationText);
    return _dialogCompleter.future;
  }

  void confirmShareFiles() {
    _showShareDialogListener();
  }

  /// Completes the _dialogCompleter to resume the Future's execution call
  void sendInput(String input) {
    _dialogCompleter.complete(input);
    _dialogCompleter = null;
  }
}
