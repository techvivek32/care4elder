import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import Otp from '@/models/Otp';
import bcrypt from 'bcryptjs';
import { sendOTP } from '@/lib/mail';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { name, email, password, phone } = await req.json();

    if (!name || !email || !password || !phone) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const existingPatient = await Patient.findOne({ email });
    if (existingPatient) {
      return NextResponse.json({ error: 'Email already registered' }, { status: 409 });
    }

    // Check if email was pre-verified via OTP flow
    const otpRecord = await Otp.findOne({ email, role: 'Patient', isVerified: true });
    const isEmailVerified = !!otpRecord;

    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate 6-digit OTP only if not verified
    let otp, otpExpiry;
    if (!isEmailVerified) {
        otp = Math.floor(100000 + Math.random() * 900000).toString();
        otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    }

    const patient = await Patient.create({
      name,
      email,
      password: hashedPassword,
      phone,
      isRelativeVerified: false,
      isEmailVerified: isEmailVerified,
      otp: isEmailVerified ? undefined : otp,
      otpExpiry: isEmailVerified ? undefined : otpExpiry
    });

    if (!isEmailVerified && otp) {
        // Send OTP via email
        const emailSent = await sendOTP(email, otp, 'Patient');
        if (!emailSent) {
          console.error(`Failed to send OTP to ${email}`);
        } else {
            console.log(`OTP sent to ${email}`);
        }

        return NextResponse.json({
          message: 'Registration successful. OTP sent to email.',
          email: patient.email
        }, { status: 201 });
    } else {
        // Cleanup OTP record if it exists
        if (otpRecord) {
            await Otp.deleteOne({ _id: otpRecord._id });
        }
        return NextResponse.json({
          message: 'Registration successful. Email verified.',
          email: patient.email
        }, { status: 201 });
    }

  } catch (error) {
    console.error('Patient Registration Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
