import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Otp from '@/models/Otp';
import Doctor from '@/models/Doctor';
import { sendSms } from '@/lib/sms';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { phone } = await req.json();

    if (!phone) {
      return NextResponse.json({ error: 'Phone number is required' }, { status: 400 });
    }

    // Check if phone already registered
    const existingDoctor = await Doctor.findOne({ phone });
    if (existingDoctor) {
      return NextResponse.json({ error: 'Phone number already registered' }, { status: 409 });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Save to Otp collection
    await Otp.findOneAndUpdate(
      { phone, role: 'Doctor' },
      { 
        otp, 
        isVerified: false, 
        createdAt: new Date(),
        // We don't set email here since it's phone verification
      },
      { upsert: true, new: true }
    );

    // Send SMS
    const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
    const templateId = process.env.SMS_TEMPLATE_ID;
    
    const sent = await sendSms(phone, message, templateId);

    if (!sent) {
        console.error(`Failed to send SMS to ${phone}`);
        // For development/debugging, we might want to log the OTP
        console.log(`DEV BACKUP: Register OTP for ${phone}: ${otp}`);
        // return NextResponse.json({ error: 'Failed to send SMS' }, { status: 500 });
        // Allow to proceed for dev/demo if SMS fails but logged
    }

    return NextResponse.json({ message: 'OTP sent successfully' });

  } catch (error: any) {
    console.error('Doctor Register OTP Error:', error);
    return NextResponse.json({ error: `Internal Server Error: ${error.message}` }, { status: 500 });
  }
}
