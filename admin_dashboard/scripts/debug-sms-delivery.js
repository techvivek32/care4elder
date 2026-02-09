const https = require('http');
const dotenv = require('dotenv');
const path = require('path');

// Load .env
dotenv.config({ path: path.join(__dirname, '../.env') });

const API_KEY = process.env.SMS_API_KEY;
const SENDER_ID = process.env.SMS_SENDER_ID;
const API_URL = process.env.SMS_API_URL || 'http://smpp.webwonderz.net/http-tokenkeyapi.php';
const DLR_URL = 'http://smpp.webwonderz.net/http-token-dlr.php';
const TEMPLATE_ID = process.env.SMS_TEMPLATE_ID;

const TEST_PHONE = '916354348913'; // Updated number with 91 prefix

async function makeRequest(urlStr) {
    return new Promise((resolve, reject) => {
        const lib = urlStr.startsWith('https') ? require('https') : require('http');
        lib.get(urlStr, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => resolve(data));
        }).on('error', (err) => reject(err));
    });
}

async function debugDelivery() {
    console.log('--- SMS Delivery Debugger ---');
    
    // 1. Send SMS
    const otp = Math.floor(1000 + Math.random() * 9000);
    const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
    
    const url = new URL(API_URL);
    url.searchParams.append('authentic-key', API_KEY);
    url.searchParams.append('senderid', SENDER_ID);
    url.searchParams.append('route', '1'); // Using Route 1 as it's the only one accepted
    url.searchParams.append('number', TEST_PHONE);
    url.searchParams.append('message', message);
    url.searchParams.append('templateid', TEMPLATE_ID);
    
    console.log(`Sending SMS to ${TEST_PHONE}...`);
    const sendResponse = await makeRequest(url.toString());
    console.log(`Send Response: ${sendResponse}`);
    
    // Parse Msg ID (Format: "msg-id : XXXXXX")
    const match = sendResponse.match(/msg-id\s*:\s*(\w+)/);
    if (!match) {
        console.error('Failed to get Message ID from response');
        return;
    }
    
    const msgId = match[1];
    console.log(`Message ID captured: ${msgId}`);
    
    // 2. Poll DLR
    console.log('Waiting 15 seconds for delivery report...');
    await new Promise(r => setTimeout(r, 15000));
    
    const dlrUrl = new URL(DLR_URL);
    dlrUrl.searchParams.append('authentic-key', API_KEY);
    dlrUrl.searchParams.append('msg_id', msgId);
    
    console.log('Checking Delivery Status...');
    const dlrResponse = await makeRequest(dlrUrl.toString());
    console.log(`Delivery Report: ${dlrResponse}`);
    
    // Interpret Result
    if (dlrResponse.includes('DELIVRD')) {
        console.log('SUCCESS: Message was delivered to handset.');
    } else if (dlrResponse.includes('DND')) {
        console.log('FAILURE: Blocked by DND (Do Not Disturb). Route 1 (Promo) cannot bypass DND.');
        console.log('SOLUTION: You MUST get Route 2 (Transactional) enabled by WebWonderz support.');
    } else if (dlrResponse.includes('REJECTD')) {
        console.log('FAILURE: Rejected by operator.');
    } else {
        console.log('STATUS: ' + dlrResponse);
    }
}

debugDelivery();