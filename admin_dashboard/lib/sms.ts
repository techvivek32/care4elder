
export async function sendSms(phone: string, message: string, templateId?: string) {
  const apiKey = process.env.SMS_API_KEY;
  const senderId = process.env.SMS_SENDER_ID;
  const apiUrl = process.env.SMS_API_URL || 'http://smpp.webwonderz.net/http-tokenkeyapi.php';

  if (!apiKey || !senderId) {
    console.warn('SMS configuration missing (SMS_API_KEY or SMS_SENDER_ID)');
    return false;
  }

  // Format phone number: Remove non-digits, ensure 91 prefix for India
  let formattedPhone = phone.replace(/\D/g, '');
  if (formattedPhone.length === 10) {
      formattedPhone = '91' + formattedPhone;
  } else if (formattedPhone.length > 10 && formattedPhone.startsWith('91')) {
      // Already correct
  } else if (formattedPhone.length > 10 && formattedPhone.startsWith('0')) {
      formattedPhone = '91' + formattedPhone.substring(1);
  }

  try {
    // WebWonderz Token API Format
    // URL: http://smpp.webwonderz.net/http-tokenkeyapi.php?authentic-key=KEY&senderid=ID&route=2&number=NUM&message=MSG&templateid=TID
    
    const url = new URL(apiUrl);
    url.searchParams.append('authentic-key', apiKey);
    url.searchParams.append('senderid', senderId);
    url.searchParams.append('route', '1'); // FALLBACK TO ROUTE 1 (PROMO) since 2/4/6 failed in testing.
                                           // Even with Template ID, Route 2 is rejected by the provider for this account.
                                           // Route 1 worked (msg-id: NDAzOTc0)
    url.searchParams.append('number', formattedPhone);
    url.searchParams.append('message', message);
    
    if (templateId) {
        url.searchParams.append('templateid', templateId);
    }

    // console.log(`Sending SMS to ${formattedPhone} via ${url.toString().replace(apiKey, 'HIDDEN_KEY')}`);

    const response = await fetch(url.toString());
    const data = await response.text(); // API returns text response usually
    
    console.log(`SMS Sent to ${formattedPhone}. Response: ${data}`);
    
    // Check for success indicators in response if needed (e.g., usually returns a message ID or "success")
    return true; 
  } catch (error) {
    console.error('SMS Send Error:', error);
    return false;
  }
}
