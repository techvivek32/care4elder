import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import RefreshToken from '@/models/RefreshToken';
import { verifyRefreshToken, signToken } from '@/lib/auth-utils';

export async function POST(req: Request) {
  try {
    await dbConnect();
    const { refreshToken } = await req.json();

    if (!refreshToken) {
      return NextResponse.json({ error: 'Refresh token required' }, { status: 400 });
    }

    // Verify signature
    const decoded = verifyRefreshToken(refreshToken);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid refresh token' }, { status: 401 });
    }

    // Check DB
    const tokenDoc = await RefreshToken.findOne({ token: refreshToken });
    if (!tokenDoc) {
      return NextResponse.json({ error: 'Refresh token not found or revoked' }, { status: 403 });
    }

    if (tokenDoc.expiresAt < new Date()) {
       await RefreshToken.deleteOne({ _id: tokenDoc._id });
       return NextResponse.json({ error: 'Refresh token expired' }, { status: 403 });
    }

    // Issue new access token
    const newAccessToken = signToken({ id: tokenDoc.user, role: (tokenDoc.userModel as string).toLowerCase() });

    return NextResponse.json({
      token: newAccessToken
    });

  } catch (error) {
    console.error('Refresh Token Error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
