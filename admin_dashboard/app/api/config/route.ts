import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Setting from '@/models/Setting';

export async function GET() {
  try {
    await dbConnect();
    const settings = await Setting.findOne();

    // Only return public configuration
    return NextResponse.json({
      razorpayKeyId: settings?.razorpayKeyId || '',
    });
  } catch (error) {
    console.error('Fetch Config Error:', error);
    return NextResponse.json({ error: 'Failed to fetch config' }, { status: 500 });
  }
}
