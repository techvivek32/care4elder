import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import { signToken, createRefreshToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { phone, otp } = await req.json();

    if (!phone || !otp) {
      return NextResponse.json({ error: 'Phone and OTP are required' }, { status: 400 });
    }

    const patient = await Patient.findOne({ phone }).select('+otp +otpExpiry');

    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    if (!patient.otp || !patient.otpExpiry) {
      return NextResponse.json({ error: 'No OTP generated' }, { status: 400 });
    }

    if (new Date() > patient.otpExpiry) {
      return NextResponse.json({ error: 'OTP expired' }, { status: 400 });
    }

    if (patient.otp !== otp) {
      return NextResponse.json({ error: 'Invalid OTP' }, { status: 400 });
    }

    // Verify
    patient.otp = undefined;
    patient.otpExpiry = undefined;
    await patient.save();

    // Clean up from Otp collection if exists (since we duplicate it there for visibility)
    try {
        const Otp = (await import('@/models/Otp')).default;
        // Use email or phone to identify. Patient model uses phone for login, but Otp collection uses email/role generally.
        // But since we saved it using email in login-otp, we should delete by email.
        if (patient.email) {
            await Otp.deleteOne({ email: patient.email, role: 'Patient' });
        }
    } catch (err) {
        console.error('Failed to cleanup Otp collection:', err);
    }

    // Generate tokens
    const token = signToken({ id: patient._id, role: 'patient' });
    const refreshToken = await createRefreshToken(patient._id.toString(), 'Patient');

    return NextResponse.json({
      message: 'Login successful',
      token,
      refreshToken,
      user: {
        id: patient._id,
        name: patient.name,
        email: patient.email,
        phone: patient.phone,
        role: 'patient',
        dateOfBirth: patient.dateOfBirth,
        isRelativeVerified: patient.isRelativeVerified
      }
    });

  } catch (error) {
    console.error('Patient Verify Login OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
