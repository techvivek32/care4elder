import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import HealthTip from '@/models/HealthTip';

export async function GET() {
  try {
    await dbConnect();
    const tips = await HealthTip.find({ isActive: true }).sort({ createdAt: -1 });
    return NextResponse.json(tips);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch health tips' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    await dbConnect();
    const body = await request.json();
    const tip = await HealthTip.create(body);
    return NextResponse.json(tip);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create health tip' }, { status: 500 });
  }
}
