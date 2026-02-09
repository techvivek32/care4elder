const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

const envPath = path.resolve(__dirname, '../.env');
if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
}

const apiKey = process.env.SMS_API_KEY;
const senderId = process.env.SMS_SENDER_ID;
const apiUrl = process.env.SMS_API_URL;
const phone = '9999999999';
const message = 'Your Care4Elder verification code is 123456.';

async function testVariation(name, params) {
    const url = new URL(apiUrl);
    url.searchParams.append('authentic-key', apiKey);
    url.searchParams.append('senderid', senderId);
    url.searchParams.append('number', phone);
    url.searchParams.append('message', message);
    
    // Add variation params
    for (const [key, value] of Object.entries(params)) {
        url.searchParams.append(key, value);
    }

    console.log(`\nTesting ${name}: ${url.toString().replace(apiKey, 'HIDDEN')}`);
    try {
        const response = await fetch(url.toString());
        const data = await response.text();
        console.log(`Response: ${data}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
    }
}

async function runTests() {
    await testVariation('Route 2', { route: '2' });
    await testVariation('Route 4', { route: '4' }); // Transactional
    await testVariation('Route 1', { route: '1' }); // Promotional
    // await testVariation('RouteID 2', { routeid: '2' });
}

async function debugDatabase() {
    const mongoose = require('mongoose');
    const dbUri = process.env.MONGODB_URI;
    
    if (!dbUri) {
        console.error('MONGODB_URI missing');
        return;
    }

    try {
        console.log('\nConnecting to MongoDB...');
        await mongoose.connect(dbUri);
        console.log('Connected.');
        
        // Check Patient schema/collection directly
        const collections = await mongoose.connection.db.listCollections().toArray();
        console.log('Collections:', collections.map(c => c.name));

        const patients = await mongoose.connection.db.collection('patients').find({}).toArray();
        console.log(`Found ${patients.length} patients.`);
        
        if (patients.length > 0) {
            const p = patients[0];
            console.log('Sample Patient:', {
                phone: p.phone,
                otp: p.otp, // Check if OTP is visible here
                otpExpiry: p.otpExpiry
            });
            
            // Try updating
            console.log('Attempting to update OTP for sample patient...');
            await mongoose.connection.db.collection('patients').updateOne(
                { _id: p._id },
                { $set: { otp: '999999', otpExpiry: new Date() } }
            );
            console.log('Update command sent.');
            
            const updated = await mongoose.connection.db.collection('patients').findOne({ _id: p._id });
            console.log('Updated Patient:', {
                phone: updated.phone,
                otp: updated.otp
            });
        }
        
        await mongoose.disconnect();
    } catch (err) {
        console.error('DB Error:', err);
    }
}

// runTests();
debugDatabase();
