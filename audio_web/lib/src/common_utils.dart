/// Check the web result 'no, maybe, probably'
bool canPlayTypeResultCheck(String canPlayTypeResult) {
  // audio/mp3 probably
  // audio/ogg maybe
  // audio/wav maybe
  // audio/dummy
  canPlayTypeResult = canPlayTypeResult.trim().toLowerCase();
  if (canPlayTypeResult.isNotEmpty) {
    switch (canPlayTypeResult) {
      case 'no':
        return false;
      default:
        return true;
    }
  }
  return false;
}
