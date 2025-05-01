import 'package:url_launcher/url_launcher.dart';

Future<void> sendSms(String phoneNumber, String message,
    {bool useWhatsApp = false}) async {
  try {
    print('Message: $message');

    // Format the phone number (remove +, spaces, and non-numeric characters)
    final String formattedPhoneNumber =
        '+91${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';
    final String encodedMessage = Uri.encodeComponent(message);

    if (useWhatsApp) {
      // Create the WhatsApp URL
      final Uri whatsappUri =
          Uri.parse('https://wa.me/$formattedPhoneNumber?text=$encodedMessage');

      print('WhatsApp URL: $whatsappUri');

      // Check if the URL can be launched
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        print('WhatsApp message sent to $phoneNumber');
      } else {
        print(
            'Could not launch WhatsApp. Ensure WhatsApp is installed and the number is registered.');
      }
    } else {
      // Create the SMS URI
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: formattedPhoneNumber,
        queryParameters: {'body': message},
      );

      // Launch SMS app
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        print('SMS intent launched to $phoneNumber');
      } else {
        print('Could not launch SMS app.');
      }
    }
  } catch (error) {
    print('Failed to send message: $error');
  }
}
