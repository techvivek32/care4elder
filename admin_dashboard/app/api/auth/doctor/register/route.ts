import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import Otp from '@/models/Otp';
import bcrypt from 'bcryptjs';
import { sendDoctorOTP } from '@/lib/mail';
import { sendSms } from '@/lib/sms';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const body = await req.json();
    const { 
      name, 
      email, 
      password, 
      phone, 
      specialization, 
      licenseNumber, 
      experienceYears,
      hospitalAffiliation,
      idNumber,
      consultationFee, 
      documents 
    } = body;

    if (!name || !email || !password || !phone || !specialization || !licenseNumber || consultationFee === undefined || consultationFee === null) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const existingDoctor = await Doctor.findOne({ email });
    if (existingDoctor) {
      return NextResponse.json({ error: 'Email already registered' }, { status: 409 });
    }

    // Check if email was pre-verified via OTP flow
    const otpRecord = await Otp.findOne({ email, role: 'Doctor', isVerified: true });
    const isEmailVerified = !!otpRecord;

    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Generate 6-digit OTP only if not verified
    let otp, otpExpiry;
    if (!isEmailVerified) {
        otp = Math.floor(100000 + Math.random() * 900000).toString();
        otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    }

    const doctor = await Doctor.create({
      name,
      email,
      password: hashedPassword,
      phone,
      specialization,
      licenseNumber,
      experienceYears,
      hospitalAffiliation,
      idNumber,
      consultationFee,
      verificationStatus: 'pending',
      walletBalance: 0,
      documents: documents || [],
      isEmailVerified: isEmailVerified,
      otp: isEmailVerified ? undefined : otp,
      otpExpiry: isEmailVerified ? undefined : otpExpiry
    });

    if (!isEmailVerified && otp) {
        // Also save to global Otp collection for visibility/debugging
        try {
            await Otp.findOneAndUpdate(
                { email: doctor.email, role: 'Doctor' },
                { 
                    otp, 
                    isVerified: false, 
                    createdAt: new Date(),
                    phone: phone
                },
                { upsert: true, new: true }
            );
        } catch (err) {
            console.error('Failed to save to global OTP collection:', err);
        }

        // Send OTP via email
        const emailSent = await sendDoctorOTP(email, otp);
        if (!emailSent) {
          console.error(`Failed to send OTP to ${email}`);
        } else {
            console.log(`OTP sent to ${email}`);
        }
        
        // Send OTP via SMS
        // Use Exact DLT Template: "{#var#} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP."
        const smsMessage = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
        const templateId = process.env.SMS_TEMPLATE_ID;
        
        await sendSms(phone, smsMessage, templateId);

        return NextResponse.json({
            message: 'Registration successful. OTP sent to email and phone.',
            email: doctor.email
        }, { status: 201 });
    } else {
        // Cleanup OTP record if it exists
        if (otpRecord) {
            await Otp.deleteOne({ _id: otpRecord._id });
        }
        return NextResponse.json({
            message: 'Registration successful. Email verified.',
            email: doctor.email
        }, { status: 201 });
    }

  } catch (error) {
    console.error('Doctor Registration Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
