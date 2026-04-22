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
    
    const { relatives, verifyPhone } = await req.json();
    
    if (!relatives || !Array.isArray(relatives) || relatives.length === 0) {
      return NextResponse.json({ error: 'At least one relative is required' }, { status: 400 });
    }

    // Fetch existing contacts before updating so we can detect new ones
    const existingPatient = await Patient.findById(decoded.id).select('emergencyContacts email');
    if (!existingPatient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    // Save all contacts
    const patient = await Patient.findByIdAndUpdate(
      decoded.id,
      { emergencyContacts: relatives },
      { new: true }
    );

    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    // If Flutter explicitly tells us which phone to verify, trust it completely.
    // Flutter already knows which contact is new (isNew flag).
    // Only send OTP when verifyPhone is provided.
    const phoneToVerify: string | null = verifyPhone ? verifyPhone.trim() : null;

    if (phoneToVerify) {
      // Generate OTP only for the new contact
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

      patient.otp = otp;
      patient.otpExpiry = otpExpiry;
      await patient.save();

      try {
        const Otp = (await import('@/models/Otp')).default;
        await Otp.findOneAndUpdate(
          { email: patient.email, role: 'Patient_Relative' },
          { otp, isVerified: false, createdAt: new Date(), phone: phoneToVerify },
          { upsert: true, new: true }
        );
      } catch (err) {
        console.error('Failed to save to global OTP collection:', err);
      }

      const { sendSms } = await import('@/lib/sms');
      const message = `${otp} is the OTP for your Care4Elder account. NEVER SHARE YOUR OTP WITH ANYONE. Care4Elder will never call or message to ask for the OTP.`;
      const templateId = process.env.SMS_TEMPLATE_ID;
      await sendSms(phoneToVerify, message, templateId);

      return NextResponse.json({
        message: 'Relatives saved successfully. OTP sent to new relative.',
        contacts: patient.emergencyContacts,
        otpSentTo: phoneToVerify,
      });
    }

    // All contacts already existed — just save, no OTP needed
    return NextResponse.json({
      message: 'Relatives saved successfully. No new contacts to verify.',
      contacts: patient.emergencyContacts,
      otpSentTo: null,
    });

  } catch (error) {
    console.error('Update Relatives Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
