import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Otp from '@/models/Otp';
import Doctor from '@/models/Doctor';
import Patient from '@/models/Patient';
import { sendOTP } from '@/lib/mail';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { email, role, intent = 'register' } = await req.json();

    if (!email || !role) {
      return NextResponse.json({ error: 'Email and role are required' }, { status: 400 });
    }

    const normalizedRole = role.charAt(0).toUpperCase() + role.slice(1).toLowerCase();
    if (!['Doctor', 'Patient'].includes(normalizedRole)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
    }

    // Check if user exists
    let existingUser;
    if (normalizedRole === 'Doctor') {
      existingUser = await Doctor.findOne({ email });
    } else {
      existingUser = await Patient.findOne({ email });
    }

    if (intent === 'register') {
      if (existingUser && existingUser.isEmailVerified) {
        return NextResponse.json({ error: 'Email already registered' }, { status: 409 });
      }
    } else if (intent === 'login') {
      if (!existingUser) {
        return NextResponse.json({ error: 'User not registered' }, { status: 404 });
      }
      if (normalizedRole === 'Doctor' && 'verificationStatus' in existingUser) {
        if (existingUser.verificationStatus !== 'approved') {
          if (existingUser.verificationStatus === 'rejected') {
            return NextResponse.json({ error: 'Account rejected' }, { status: 403 });
          }
        }
      }
    }
    
    // If user exists but is not verified, allow sending OTP (Resend flow)

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Upsert OTP document
    await Otp.findOneAndUpdate(
      { email, role: normalizedRole },
      { otp, isVerified: false, createdAt: new Date() },
      { upsert: true, new: true }
    );

    // Send Email
    const emailSent = await sendOTP(email, otp, normalizedRole as 'Doctor' | 'Patient');

    if (!emailSent) {
      return NextResponse.json({ error: 'Failed to send OTP email' }, { status: 500 });
    }

    return NextResponse.json({ message: 'OTP sent successfully' }, { status: 200 });

  } catch (error) {
    console.error('Send OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
