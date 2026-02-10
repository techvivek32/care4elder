import { NextResponse } from 'next/server';
import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

const APP_ID = 'ae6f0f0e29904fa88c92b1d52b98acc5';
const APP_CERTIFICATE = 'a2d43b5fc0214d0d86a4c75b93925534';

export async function POST(request: Request) {
  try {
    const { channelName, uid, role = 'publisher', expiryTime = 3600 } = await request.json();

    if (!channelName) {
      return NextResponse.json({ error: 'channelName is required' }, { status: 400 });
    }

    // UID can be 0 (let Agora assign) or a specific number. 
    // If string is passed, we might need to use buildTokenWithAccount.
    // For simplicity, let's assume numeric UID or 0.
    const uidNum = uid ? parseInt(uid) : 0;
    
    const rtcRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expiryTime;

    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uidNum,
      rtcRole,
      privilegeExpiredTs
    );

    return NextResponse.json({ token, appId: APP_ID, channelName, uid: uidNum });
  } catch (error) {
    console.error('Error generating Agora token:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
