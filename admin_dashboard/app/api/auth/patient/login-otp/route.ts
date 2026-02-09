import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { phone } = await req.json();

    if (!phone) {
      return NextResponse.json({ error: 'Phone number is required' }, { status: 400 });
    }

    const patient = await Patient.findOne({ phone });
    if (!patient) {
      return NextResponse.json({ error: 'Phone number not registered' }, { status: 404 });
    }

    // Generate Static OTP
    const otp = '123456';
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    patient.otp = otp;
    patient.otpExpiry = otpExpiry;
    await patient.save();

    // In a real app, send SMS here.
    console.log(`Login OTP for ${phone}: ${otp}`);

    return NextResponse.json({
      message: 'OTP sent successfully',
      phone: patient.phone
    });

  } catch (error) {
    console.error('Patient Login OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
