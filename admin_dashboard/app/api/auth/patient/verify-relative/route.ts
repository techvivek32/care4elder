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
    
    // In a real app, you would verify the OTP here. 
    // For this implementation, we assume the OTP check passed or is handled here.
    // Since the prompt asks for the backend to support the flow:
    
    const { otp } = await req.json();
    
    // Mock OTP verification (Accept '123456')
    if (otp !== '123456') {
       return NextResponse.json({ error: 'Invalid OTP' }, { status: 400 });
    }

    const patient = await Patient.findByIdAndUpdate(
      decoded.id,
      { isRelativeVerified: true },
      { new: true }
    );

    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    return NextResponse.json({
      message: 'Relative verification successful',
      user: {
        id: patient._id,
        name: patient.name,
        email: patient.email,
        role: 'patient',
        isRelativeVerified: patient.isRelativeVerified
      }
    });

  } catch (error) {
    console.error('Relative Verification Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
