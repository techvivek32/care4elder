import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import CallRequest from '@/models/CallRequest';
import Patient from '@/models/Patient';
import Doctor from '@/models/Doctor';
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

export async function GET(request: Request) {
  try {
    await dbConnect();
    
    // Ensure models are registered for populate
    if (!Patient || !Doctor) {
      throw new Error('Models not loaded');
    }

    const authUser = getAuthUser(request);
    if (!authUser?.id || authUser.role !== 'doctor') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Fetch calls for this doctor that are completed, cancelled, or declined
    const calls = await CallRequest.find({
      doctorId: authUser.id,
      status: { $in: ['completed', 'cancelled', 'declined', 'timeout'] }
    })
    .sort({ createdAt: -1 })
    .populate('patientId', 'name dateOfBirth profilePictureUrl location');

    return NextResponse.json(calls);
  } catch (error) {
    console.error('Fetch Doctor History Error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch history' },
      { status: 500 }
    );
  }
}
