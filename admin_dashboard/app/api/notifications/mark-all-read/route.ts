import { NextRequest, NextResponse } from 'next/server';
import { connectDB } from '@/lib/mongodb';
import Notification from '@/models/Notification';
import { verifyToken } from '@/lib/auth';

// POST - Mark all notifications as read
export async function POST(request: NextRequest) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const decoded = verifyToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    await connectDB();

    await Notification.updateMany(
      { userId: decoded.userId, isRead: false },
      { isRead: true }
    );

    return NextResponse.json({ message: 'All notifications marked as read' });
  } catch (error: any) {
    console.error('Error marking all as read:', error);
    return NextResponse.json(
      { error: 'Failed to mark all as read' },
      { status: 500 }
    );
  }
}
