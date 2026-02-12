
import dbConnect from './admin_dashboard/lib/db';
import Doctor from './admin_dashboard/models/Doctor';
import CallRequest from './admin_dashboard/models/CallRequest';
import mongoose from 'mongoose';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(process.cwd(), 'admin_dashboard', '.env.local') });

async function investigate() {
  try {
    await dbConnect();
    const doctorId = '698cbc5cd70fd21be79b60fa';
    const doctor = await Doctor.findById(doctorId);
    
    if (!doctor) {
      console.log('Doctor not found');
      return;
    }
    
    console.log('--- Doctor Info ---');
    console.log('Name:', doctor.name);
    console.log('Wallet Balance:', doctor.walletBalance);
    console.log('Verification Status:', doctor.verificationStatus);
    console.log('Documents:', JSON.stringify(doctor.documents, null, 2));
    console.log('Profile Image:', doctor.profileImage);
    
    const completedConsultations = await CallRequest.countDocuments({
      doctorId: doctorId,
      status: 'completed'
    });
    console.log('Completed Consultations (Count):', completedConsultations);

    const allConsultations = await CallRequest.find({ doctorId: doctorId });
    console.log('Total Call Requests for this doctor:', allConsultations.length);
    if (allConsultations.length > 0) {
        console.log('Sample Call Request Statuses:', allConsultations.slice(0, 5).map(c => c.status));
    }

    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

investigate();
