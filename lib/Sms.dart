import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> sendSms(String phoneNumber, String message,
    {bool useWhatsApp = false}) async {
  try {
    print(message);

    if (useWhatsApp) {
      // Format the phone number for WhatsApp
      final String formattedPhoneNumber =
          phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      final String encodedMessage = Uri.encodeComponent(message);

      // Create the WhatsApp URL
      final Uri whatsappUri =
          Uri.parse('https://wa.me/$formattedPhoneNumber?text=$encodedMessage');

      // Launch WhatsApp
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        print('WhatsApp message sent to $phoneNumber');
      } else {
        print('Could not launch WhatsApp');
      }
    } else {
      // Request SMS permission
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }

      if (status.isGranted) {
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: phoneNumber,
          queryParameters: {'body': message},
        );

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          print('SMS sent to $phoneNumber');
        } else {
          print('Could not launch SMS app');
        }
      } else {
        print('SMS permission denied');
      }
    }
  } catch (error) {
    print('Failed to send message: $error');
  }
}
