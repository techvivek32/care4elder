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
    
    // Retrieve patient with OTP fields
    const patientWithOtp = await Patient.findById(decoded.id).select('+otp +otpExpiry');
    
    if (!patientWithOtp) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    if (!patientWithOtp.otp || !patientWithOtp.otpExpiry) {
      return NextResponse.json({ error: 'No OTP generated' }, { status: 400 });
    }

    if (new Date() > patientWithOtp.otpExpiry) {
      return NextResponse.json({ error: 'OTP expired' }, { status: 400 });
    }
    
    if (patientWithOtp.otp !== otp) {
       return NextResponse.json({ error: 'Invalid OTP' }, { status: 400 });
    }

    const patient = await Patient.findByIdAndUpdate(
      decoded.id,
      { 
          isRelativeVerified: true,
          otp: undefined,
          otpExpiry: undefined
      },
      { new: true }
    );

    // Cleanup global OTP
    try {
         const Otp = (await import('@/models/Otp')).default;
         await Otp.deleteOne({ email: patientWithOtp.email, role: 'Patient_Relative' });
    } catch (err) {
         console.error('Failed to cleanup Otp collection:', err);
    }

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
