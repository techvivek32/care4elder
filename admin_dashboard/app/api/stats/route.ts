import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import Patient from '@/models/Patient';
import SOSAlert from '@/models/SOSAlert';

export async function GET() {
  try {
    await dbConnect();
    
    const [totalDoctors, totalPatients, activeSOS, pendingDoctors] = await Promise.all([
      Doctor.countDocuments(),
      Patient.countDocuments(),
      SOSAlert.countDocuments({ status: 'active' }),
      Doctor.countDocuments({ verificationStatus: 'pending' })
    ]);

    return NextResponse.json({
      totalDoctors,
      totalPatients,
      activeSOS,
      pendingDoctors
    });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch stats' }, { status: 500 });
  }
}
