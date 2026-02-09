import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import { verifyToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    
    // Extract token from header
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    
    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    
    if (!decoded || typeof decoded !== 'object' || !('id' in decoded)) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }
    
    const { relatives } = await req.json();
    
    if (!relatives || !Array.isArray(relatives) || relatives.length === 0) {
      return NextResponse.json({ error: 'At least one relative is required' }, { status: 400 });
    }

    const patient = await Patient.findByIdAndUpdate(
      decoded.id,
      { emergencyContacts: relatives },
      { new: true }
    );

    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    // In a real app, we would generate and send an OTP here.
    // For this requirement, we will use static OTP 123456 in the verification step.
    // We can return success here.

    return NextResponse.json({
      message: 'Relatives saved successfully',
      contacts: patient.emergencyContacts
    });

  } catch (error) {
    console.error('Update Relatives Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
