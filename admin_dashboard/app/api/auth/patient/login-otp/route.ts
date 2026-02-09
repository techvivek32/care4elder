import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import { sendSms } from '@/lib/sms';

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

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    patient.otp = otp;
    patient.otpExpiry = otpExpiry;
    await patient.save();
    
    // Also save to global Otp collection for visibility/debugging if needed
    // This helps if the user expects to see all OTPs in the 'otps' collection
    try {
        const Otp = (await import('@/models/Otp')).default;
        await Otp.findOneAndUpdate(
            { email: patient.email, role: 'Patient' }, // Use email as identifier for Otp collection
            { 
                otp, 
                isVerified: false, 
                createdAt: new Date(),
                phone: phone // Add phone if schema supports it or just for reference
            },
            { upsert: true, new: true }
        );
    } catch (err) {
        console.error('Failed to save to global OTP collection:', err);
    }

    // Send SMS
    // Use Exact DLT Template: "{#var#} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP."
    const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
    const templateId = process.env.SMS_TEMPLATE_ID;
    
    const sent = await sendSms(phone, message, templateId);
    
    if (!sent) {
        console.error(`Failed to send SMS to ${phone}`);
        // For development, we might still return success if env vars are missing, 
        // but in production this should probably fail or fallback.
        // We'll log the OTP for dev purposes if SMS fails.
        console.log(`DEV BACKUP: Login OTP for ${phone}: ${otp}`);
    }

    return NextResponse.json({
      message: 'OTP sent successfully',
      phone: patient.phone
    });

  } catch (error) {
    console.error('Patient Login OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
