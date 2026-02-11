import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import bcrypt from 'bcryptjs';
import { signToken, createRefreshToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const body = await req.json();
    console.log('Login Request Body:', body);
    const { email, password } = body;

    if (!email || !password) {
      console.log('Login failed: Missing email or password');
      return NextResponse.json({ error: 'Missing email or password' }, { status: 400 });
    }

    const patient = await Patient.findOne({ email }).select('+password');
    if (!patient || !patient.password) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    const isMatch = await bcrypt.compare(password, patient.password);
    if (!isMatch) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    // Check email verification
    if (!patient.isEmailVerified) {
       return NextResponse.json({ error: 'Email not verified. Please verify your email first.' }, { status: 403 });
    }

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
        role: 'patient',
        dateOfBirth: patient.dateOfBirth,
        isRelativeVerified: patient.isRelativeVerified
      }
    });

  } catch (error) {
    console.error('Patient Login Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
