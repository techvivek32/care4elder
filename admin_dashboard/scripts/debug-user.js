const mongoose = require('mongoose');
const Patient = require('../models/Patient').default;
require('dotenv').config({ path: '.env.local' });

async function checkUser() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/caresafe_db';
  await mongoose.connect(uri);
  
  const email = "testpatient@example.com";
  const patient = await mongoose.models.Patient.findOne({ email }).select('+password');
  
  console.log('Found Patient:', patient);
  if (patient) {
      console.log('Password Hash:', patient.password);
  }
  
  await mongoose.disconnect();
}

checkUser().catch(console.error);
