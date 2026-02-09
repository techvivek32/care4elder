const https = require('http');
const dotenv = require('dotenv');
const path = require('path');

// Load .env
dotenv.config({ path: path.join(__dirname, '../.env') });

const API_KEY = process.env.SMS_API_KEY;
const DLR_URL = 'http://smpp.webwonderz.net/http-token-dlr.php';
const MSG_ID = 'NDAzOTgw'; // Updated ID for new number

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

async function checkDlr() {
    console.log(`Checking DLR for ${MSG_ID}...`);
    
    const dlrUrl = new URL(DLR_URL);
    dlrUrl.searchParams.append('authentic-key', API_KEY);
    dlrUrl.searchParams.append('msg_id', MSG_ID);
    
    const dlrResponse = await makeRequest(dlrUrl.toString());
    console.log(`Delivery Report: ${dlrResponse}`);
}

checkDlr();