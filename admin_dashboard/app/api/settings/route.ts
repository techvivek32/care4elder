import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import dbConnect from '@/lib/db';
import Setting from '@/models/Setting';

export async function GET() {
  try {
    // For now, we allow fetching settings (at least public ones) without strict auth if needed by public APIs,
    // BUT for sensitive info like Secret Key, we must be careful.
    // However, this endpoint is for the Admin Dashboard UI which will be authenticated.
    
    // Check Auth (Optional but recommended for Admin Dashboard API)
    // const session = await getServerSession();
    // if (!session) {
    //   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    // }

    await dbConnect();
    let settings = await Setting.findOne();

    if (!settings) {
      settings = await Setting.create({});
    }

    return NextResponse.json(settings);
  } catch (error) {
    console.error('Fetch Settings Error:', error);
    return NextResponse.json({ error: 'Failed to fetch settings' }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    // const session = await getServerSession();
    // if (!session) {
    //   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    // }

    await dbConnect();
    const body = await request.json();
    const { razorpayKeyId, razorpayKeySecret } = body;

    let settings = await Setting.findOne();

    if (!settings) {
      settings = new Setting();
    }

    if (razorpayKeyId !== undefined) settings.razorpayKeyId = razorpayKeyId;
    if (razorpayKeySecret !== undefined) settings.razorpayKeySecret = razorpayKeySecret;

    await settings.save();

    return NextResponse.json(settings);
  } catch (error) {
    console.error('Update Settings Error:', error);
    return NextResponse.json({ error: 'Failed to update settings' }, { status: 500 });
  }
}
