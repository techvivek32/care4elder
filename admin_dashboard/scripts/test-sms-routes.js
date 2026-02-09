const https = require('http'); // The URL is http, not https based on .env
const dotenv = require('dotenv');
const path = require('path');

// Load .env from admin_dashboard
dotenv.config({ path: path.join(__dirname, '../.env') });

const API_KEY = process.env.SMS_API_KEY;
const SENDER_ID = process.env.SMS_SENDER_ID;
const API_URL = process.env.SMS_API_URL || 'http://smpp.webwonderz.net/http-tokenkeyapi.php';
const TEMPLATE_ID = process.env.SMS_TEMPLATE_ID;

// CHANGE THIS TO YOUR REAL TESTING NUMBER
const TEST_PHONE = '8248744122'; 

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

async function testRoutes() {
    console.log('--- Starting SMS Transactional Route Test ---');
    console.log(`API URL: ${API_URL}`);
    console.log(`Sender ID: ${SENDER_ID}`);
    console.log(`Template ID: ${TEMPLATE_ID}`);
    console.log(`Target Phone: ${TEST_PHONE}`);

    if (!TEMPLATE_ID) {
         console.error('ERROR: SMS_TEMPLATE_ID is missing in .env');
         return;
     }

     const otp = Math.floor(1000+Math.random()*9000);
     // Exact message format matching DLT template
     const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
     
     // Ensure phone has 91 prefix
     // const phone = '91' + TEST_PHONE;
 
     // Test alternative routes
     const routes = [1, 2]; // Test Route 1 (known working) and 2 (target)
     const formats = [
        TEST_PHONE,             // 8248744122
        '91' + TEST_PHONE,      // 918248744122
        '+91' + TEST_PHONE      // +918248744122
     ];
     
     for (const route of routes) {
        for (const phone of formats) {
            console.log(`\nTesting Route: ${route} | Phone: ${phone}`);
            console.log(`Message: ${message}`);
            
            try {
                const url = new URL(API_URL);
                url.searchParams.append('authentic-key', API_KEY);
                url.searchParams.append('senderid', SENDER_ID);
                url.searchParams.append('route', route.toString());
                url.searchParams.append('number', phone);
                url.searchParams.append('message', message);
                url.searchParams.append('templateid', TEMPLATE_ID);
                
                console.log('Sending request...');
                const data = await makeRequest(url.toString());
                console.log(`Result: ${data}`);
            } catch (error) {
                console.error(`Error: ${error.message}`);
            }
            await new Promise(r => setTimeout(r, 1000));
        }
     }
}

testRoutes();
