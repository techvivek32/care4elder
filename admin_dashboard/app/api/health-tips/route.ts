import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import HealthTip from '@/models/HealthTip';
import Notification from '@/models/Notification';
import User from '@/models/User';

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
    
    // Create notification for all patients
    const patients = await User.find({ role: 'patient' }).select('_id');
    const notifications = patients.map(patient => ({
      userId: patient._id,
      title: 'New Health Tip',
      body: tip.title,
      type: 'tip',
      isRead: false,
    }));
    
    if (notifications.length > 0) {
      await Notification.insertMany(notifications);
    }
    
    return NextResponse.json(tip);
  } catch (error) {
    console.error('Error creating health tip:', error);
    return NextResponse.json({ error: 'Failed to create health tip' }, { status: 500 });
  }
}
