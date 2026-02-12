
import dbConnect from './admin_dashboard/lib/db';
import Doctor from './admin_dashboard/models/Doctor';
import CallRequest from './admin_dashboard/models/CallRequest';
import WithdrawalRequest from './admin_dashboard/models/WithdrawalRequest';
import mongoose from 'mongoose';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(process.cwd(), 'admin_dashboard', '.env.local') });

async function investigate() {
  try {
    await dbConnect();
    // Use the ID provided by the user if possible, or search for any doctor with issues
    const doctorId = '698cbc5cd70fd21be79b60fa'; 
    const doctor = await Doctor.findById(doctorId);
    
    if (!doctor) {
      console.log('Doctor not found');
      // List all doctors to find a valid one
      const doctors = await Doctor.find({}, 'name _id walletBalance');
      console.log('Available Doctors:', doctors.map(d => `${d.name} (${d._id}) - Bal: ${d.walletBalance}`));
      mongoose.connection.close();
      return;
    }
    
    console.log('--- Doctor Info ---');
    console.log('Name:', doctor.name);
    console.log('Stored Wallet Balance:', doctor.walletBalance);
    console.log('Verification Status:', doctor.verificationStatus);
    
    const completedCalls = await CallRequest.find({
      doctorId: doctorId,
      status: 'completed'
    });
    console.log('Completed Consultations:', completedCalls.length);

    const totalEarnings = completedCalls.reduce((sum, call) => {
      const earned = call.baseFee || call.fee || 0;
      return sum + earned;
    }, 0);
    console.log('Calculated Total Earnings:', totalEarnings);

    const creditedWithdrawals = await WithdrawalRequest.find({
      doctorId: doctorId,
      status: 'credited'
    });
    console.log('Credited Withdrawals Count:', creditedWithdrawals.length);

    const totalWithdrawn = creditedWithdrawals.reduce((sum, req) => {
      return sum + (req.amount || 0);
    }, 0);
    console.log('Total Withdrawn:', totalWithdrawn);

    const calculatedBalance = Math.max(0, totalEarnings - totalWithdrawn);
    console.log('Calculated Wallet Balance:', calculatedBalance);

    if (doctor.walletBalance !== calculatedBalance) {
        console.log('MISMATCH DETECTED!');
    } else {
        console.log('Balance matches database stored value.');
    }

    // Check document paths
    console.log('--- Document Verification ---');
    console.log('Profile Image:', doctor.profileImage);
    console.log('Documents:', doctor.documents);

    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

investigate();
