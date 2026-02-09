import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import { verifyToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    
    // Extract token from header
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    
    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    
    if (!decoded || typeof decoded !== 'object' || !('id' in decoded)) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }
    
    const { relatives } = await req.json();
    
    if (!relatives || !Array.isArray(relatives) || relatives.length === 0) {
      return NextResponse.json({ error: 'At least one relative is required' }, { status: 400 });
    }

    const patient = await Patient.findByIdAndUpdate(
      decoded.id,
      { emergencyContacts: relatives },
      { new: true }
    );

    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    // Save OTP to patient
    patient.otp = otp;
    patient.otpExpiry = otpExpiry;
    await patient.save();

    // Get relative's phone (assume the first one needs verification or the last added)
    // For safety, we'll try to verify the first relative's phone if available
    const relativePhone = relatives[0]?.phone;

    if (relativePhone) {
         // Save to global Otp collection
         try {
            const Otp = (await import('@/models/Otp')).default;
            await Otp.findOneAndUpdate(
                { email: patient.email, role: 'Patient_Relative' }, // Use a distinct role or key
                { 
                    otp, 
                    isVerified: false, 
                    createdAt: new Date(),
                    phone: relativePhone
                },
                { upsert: true, new: true }
            );
         } catch (err) {
            console.error('Failed to save to global OTP collection:', err);
         }

         // Send SMS
         const { sendSms } = await import('@/lib/sms');
         const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
         const templateId = process.env.SMS_TEMPLATE_ID;
         
         await sendSms(relativePhone, message, templateId);
    }

    return NextResponse.json({
      message: 'Relatives saved successfully. OTP sent to relative.',
      contacts: patient.emergencyContacts
    });

  } catch (error) {
    console.error('Update Relatives Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
