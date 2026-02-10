import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Otp from '@/models/Otp';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { phone, otp } = await req.json();

    if (!phone || !otp) {
      return NextResponse.json({ error: 'Phone and OTP are required' }, { status: 400 });
    }

    const otpRecord = await Otp.findOne({ phone, role: 'Doctor' });

    if (!otpRecord) {
      return NextResponse.json({ error: 'Invalid or expired OTP' }, { status: 400 });
    }

    if (otpRecord.otp !== otp) {
      return NextResponse.json({ error: 'Invalid OTP' }, { status: 400 });
    }

    // Mark as verified
    // otpRecord.isVerified = true;
    // await otpRecord.save();
    
    // Remove from database as requested ("if one time that otp verify then remove that from database")
    await Otp.deleteOne({ _id: otpRecord._id });

    // We can optionally return a temporary token or just success
    return NextResponse.json({ message: 'Phone verified successfully', success: true });

  } catch (error) {
    console.error('Doctor Verify Register OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
