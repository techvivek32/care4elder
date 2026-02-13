import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import { sendSms } from '@/lib/sms';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { phone } = await req.json();

    if (!phone) {
      return NextResponse.json({ error: 'Phone number is required' }, { status: 400 });
    }

    let doctor = await Doctor.findOne({ phone });
    
    // Google Play Store Test Account Bypass
    if (phone.endsWith('1234567890')) {
        return NextResponse.json({
            message: 'OTP sent successfully (Test)',
            phone: phone
        });
    }

    if (!doctor) {
      return NextResponse.json({ error: 'Phone number not registered' }, { status: 404 });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    doctor.otp = otp;
    doctor.otpExpiry = otpExpiry;
    await doctor.save();
    
    // Also save to global Otp collection for visibility/debugging
    try {
        const Otp = (await import('@/models/Otp')).default;
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

    // Send SMS
    const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
    const templateId = process.env.SMS_TEMPLATE_ID;
    
    const sent = await sendSms(phone, message, templateId);
    
    if (!sent) {
        console.error(`Failed to send SMS to ${phone}`);
        console.log(`DEV BACKUP: Login OTP for ${phone}: ${otp}`);
    }

    return NextResponse.json({
      message: 'OTP sent successfully',
      phone: doctor.phone
    });

  } catch (error) {
    console.error('Doctor Login OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
