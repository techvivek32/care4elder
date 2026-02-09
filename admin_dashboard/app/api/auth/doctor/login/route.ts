import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import bcrypt from 'bcryptjs';
import { signToken, createRefreshToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { identifier, email, phone, password } = await req.json();

    const rawIdentifier = (email || phone || identifier || '').toString().trim();
    if (!rawIdentifier || !password) {
      return NextResponse.json({ error: 'Missing identifier or password' }, { status: 400 });
    }

    const isEmail = rawIdentifier.includes('@');
    const doctor = await Doctor.findOne(
      isEmail ? { email: rawIdentifier } : { phone: rawIdentifier },
    ).select('+password');
    if (!doctor || !doctor.password) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    const isMatch = await bcrypt.compare(password, doctor.password);
    if (!isMatch) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    // Check email verification
    if (!doctor.isEmailVerified) {
       return NextResponse.json({ error: 'Email not verified. Please verify your email first.' }, { status: 403 });
    }

    // Check verification status
    if (doctor.verificationStatus === 'rejected') {
      return NextResponse.json({ error: 'Your account has been rejected. Please contact support.' }, { status: 403 });
    }
    
    // Note: We allow 'pending' login so they can see the "Pending Verification" screen, 
    // but the frontend should handle the redirection based on status.
    // If strict blocking is required:
    // if (doctor.verificationStatus !== 'approved') {
    //   return NextResponse.json({ error: 'Account pending verification' }, { status: 403 });
    // }

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
        role: 'doctor',
        verificationStatus: doctor.verificationStatus
      }
    });

  } catch (error) {
    console.error('Doctor Login Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
