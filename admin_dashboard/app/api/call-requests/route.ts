import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import CallRequest from '@/models/CallRequest';
import Doctor from '@/models/Doctor';
import Patient from '@/models/Patient';
import Setting from '@/models/Setting';
import { verifyToken } from '@/lib/auth-utils';

const getAuthUser = (request: Request) => {
  const authHeader = request.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.split(' ')[1];
  const decoded = verifyToken(token);
  if (!decoded || typeof decoded !== 'object') {
    return null;
  }
  return decoded as { id?: string; role?: string };
};

export async function POST(request: Request) {
  try {
    await dbConnect();
    const authUser = getAuthUser(request);
    if (!authUser?.id || authUser.role !== 'patient') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { doctorId, patientId, consultationType, fee } = await request.json();

    if (!doctorId || !patientId || !fee) {
      return NextResponse.json(
        { error: 'doctorId, patientId, and fee are required' },
        { status: 400 }
      );
    }

    if (authUser.id !== patientId) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const doctor = await Doctor.findById(doctorId);
    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    if (!doctor.isAvailable) {
      return NextResponse.json({ error: 'Doctor is offline' }, { status: 409 });
    }

    const patient = await Patient.findById(patientId);
    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    // Get commission settings
    const settings = await Setting.findOne();
    const isEmergency = consultationType === 'emergency';
    const commissionPercentage = isEmergency 
      ? (settings?.emergencyCommission ?? 0) 
      : (settings?.standardCommission ?? 0);

    const commission = (fee * commissionPercentage) / (100 + commissionPercentage);
    const baseFee = fee - commission;

    const callRequest = await CallRequest.create({
      doctorId,
      patientId,
      consultationType: consultationType ?? 'consultation',
      fee,
      baseFee,
      commission,
    });

    if (!callRequest.channelName) {
      callRequest.channelName = callRequest._id.toString();
      await callRequest.save();
    }

    const populated = await CallRequest.findById(callRequest._id)
      .populate('patientId', 'name')
      .populate('doctorId', 'name');

    return NextResponse.json(populated);
  } catch (error) {
    console.error('Create Call Request Error:', error);
    return NextResponse.json(
      { error: 'Failed to create call request' },
      { status: 500 }
    );
  }
}

export async function GET(request: Request) {
  try {
    await dbConnect();
    const authUser = getAuthUser(request);
    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const doctorId = searchParams.get('doctorId');
    const status = searchParams.get('status') ?? 'ringing';

    if (!doctorId) {
      return NextResponse.json({ error: 'doctorId is required' }, { status: 400 });
    }

    if (authUser.role !== 'doctor' || authUser.id !== doctorId) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const callRequests = await CallRequest.find({
      doctorId,
      status,
    })
      .populate('patientId', 'name')
      .populate('doctorId', 'name')
      .sort({ createdAt: -1 })
      .limit(1);

    return NextResponse.json(callRequests);
  } catch (error) {
    console.error('Fetch Call Requests Error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch call requests' },
      { status: 500 }
    );
  }
}
