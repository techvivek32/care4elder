import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import SOSAlert from '@/models/SOSAlert';
import Patient from '@/models/Patient'; // Ensure Patient model is registered

export async function GET(request: Request) {
  try {
    await dbConnect();
    
    // Ensure models are registered
    if (!Patient) {
      throw new Error('Patient model not loaded');
    }

    // Fetch active alerts and populate patient details
    const alerts = await SOSAlert.find({ status: 'active' })
      .populate('patientId', 'name phone emergencyContacts')
      .sort({ timestamp: -1 });
      
    return NextResponse.json(alerts);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to fetch SOS alerts' }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
    try {
        await dbConnect();
        const { id, status } = await request.json();
        
        const alert = await SOSAlert.findByIdAndUpdate(id, { status }, { new: true });
        return NextResponse.json(alert);
    } catch (error) {
        return NextResponse.json({ error: 'Failed to update alert' }, { status: 500 });
    }
}
