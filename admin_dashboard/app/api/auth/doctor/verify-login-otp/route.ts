import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import { signToken, createRefreshToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { phone, otp } = await req.json();

    if (!phone || !otp) {
      return NextResponse.json({ error: 'Phone and OTP are required' }, { status: 400 });
    }

    const doctor = await Doctor.findOne({ phone }).select('+otp +otpExpiry');

    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    if (!doctor.otp || !doctor.otpExpiry) {
      return NextResponse.json({ error: 'No OTP generated' }, { status: 400 });
    }

    if (new Date() > doctor.otpExpiry) {
      return NextResponse.json({ error: 'OTP expired' }, { status: 400 });
    }

    if (doctor.otp !== otp) {
      return NextResponse.json({ error: 'Invalid OTP' }, { status: 400 });
    }

    // Verify
    doctor.otp = undefined;
    doctor.otpExpiry = undefined;
    await doctor.save();

    // Clean up from Otp collection if exists
    try {
        const Otp = (await import('@/models/Otp')).default;
        if (doctor.email) {
            await Otp.deleteOne({ email: doctor.email, role: 'Doctor' });
        }
    } catch (err) {
        console.error('Failed to cleanup Otp collection:', err);
    }

    // Generate tokens
    const token = signToken({ id: doctor._id, role: 'doctor' });
    const refreshToken = await createRefreshToken(doctor._id.toString(), 'Doctor');

    return NextResponse.json({
      message: 'Login successful',
      token,
      refreshToken,
      user: {
        id: doctor._id,
        name: doctor.name,
        email: doctor.email,
        phone: doctor.phone,
        role: 'doctor',
        verificationStatus: doctor.verificationStatus
      }
    });

  } catch (error) {
    console.error('Doctor Verify Login OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
