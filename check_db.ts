
import dbConnect from './admin_dashboard/lib/db';
import Doctor from './admin_dashboard/models/Doctor';
import mongoose from 'mongoose';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load env vars from admin_dashboard/.env.local or .env
dotenv.config({ path: path.join(process.cwd(), 'admin_dashboard', '.env.local') });

async function checkDoctor() {
  try {
    await dbConnect();
    const doctorId = '698cbc5cd70fd21be79b60fa';
    const doctor = await Doctor.findById(doctorId);
    
    if (!doctor) {
      console.log('Doctor not found');
      return;
    }
    
    console.log('Doctor Name:', doctor.name);
    console.log('Documents:', JSON.stringify(doctor.documents, null, 2));
    console.log('Profile Image:', doctor.profileImage);
    
    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkDoctor();
