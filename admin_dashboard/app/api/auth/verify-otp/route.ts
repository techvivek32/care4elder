import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Otp from '@/models/Otp';
import Doctor from '@/models/Doctor';
import Patient from '@/models/Patient';
import { signToken, createRefreshToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { email, otp, role } = await req.json();

    if (!email || !otp || !role) {
      return NextResponse.json({ error: 'Email, OTP, and role are required' }, { status: 400 });
    }

    const normalizedRole = role.charAt(0).toUpperCase() + role.slice(1).toLowerCase();

    const otpRecord = await Otp.findOne({ email, role: normalizedRole });

    if (!otpRecord) {
      return NextResponse.json({ error: 'Invalid or expired OTP' }, { status: 400 });
    }

    if (otpRecord.otp !== otp) {
      return NextResponse.json({ error: 'Invalid OTP' }, { status: 400 });
    }

    // Mark as verified
    otpRecord.isVerified = true;
    await otpRecord.save();

    let user;
    let token;
    let refreshToken;

    // Update user record and generate tokens if user exists (Login flow)
    if (normalizedRole === 'Doctor') {
      user = await Doctor.findOneAndUpdate({ email }, { isEmailVerified: true, isAvailable: false }, { new: true });
    } else {
      user = await Patient.findOneAndUpdate({ email }, { isEmailVerified: true }, { new: true });
    }

    if (user) {
        // Generate tokens for login
        token = signToken({ id: user._id, role: normalizedRole.toLowerCase() });
        refreshToken = await createRefreshToken(user._id.toString(), normalizedRole);
        
        return NextResponse.json({ 
            message: 'OTP verified successfully',
            token,
            refreshToken,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: normalizedRole.toLowerCase(),
                dateOfBirth: 'dateOfBirth' in user ? (user as any).dateOfBirth : undefined,
                ...(normalizedRole === 'Doctor' && 'verificationStatus' in user
                  ? { verificationStatus: user.verificationStatus }
                  : {})
            }
        }, { status: 200 });
    }

    // Registration flow (user might not exist yet if verifying before create, or exists but we just verify email)
    return NextResponse.json({ message: 'OTP verified successfully' }, { status: 200 });

  } catch (error) {
    console.error('Verify OTP Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
