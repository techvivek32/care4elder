import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import SOSAlert from '@/models/SOSAlert';
import Patient from '@/models/Patient'; // Ensure Patient model is registered
import Appointment from '@/models/Appointment';
import Doctor from '@/models/Doctor';

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;

    // Ensure models are registered
    if (!Patient || !Doctor || !Appointment) {
      throw new Error('Models not loaded');
    }

    const alert = await SOSAlert.findById(id)
      .populate('patientId'); // Populate full patient details including emergency contacts
      
    if (!alert) {
      return NextResponse.json({ error: 'Alert not found' }, { status: 404 });
    }

    // Fetch recent doctors for this patient from appointments
    // We get unique doctors from the last 10 appointments
    const appointments = await Appointment.find({ patientId: alert.patientId._id })
      .sort({ dateTime: -1 })
      .limit(10)
      .populate('doctorId', 'name phone specialization profileImage');

    // Extract unique doctors
    const doctorMap = new Map();
    appointments.forEach((app: any) => {
      if (app.doctorId && !doctorMap.has(app.doctorId._id.toString())) {
        doctorMap.set(app.doctorId._id.toString(), app.doctorId);
      }
    });
    
    const doctors = Array.from(doctorMap.values());

    return NextResponse.json({
      ...alert.toObject(),
      doctors
    });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to fetch SOS alert' }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    
    await SOSAlert.findByIdAndDelete(id);
    
    return NextResponse.json({ message: 'Alert deleted successfully' });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to delete alert' }, { status: 500 });
  }
}
