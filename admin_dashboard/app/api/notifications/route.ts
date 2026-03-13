import { NextRequest, NextResponse } from 'next/server';
import { connectDB } from '@/lib/mongodb';
import Notification from '@/models/Notification';
import { verifyToken } from '@/lib/auth';

// GET - Fetch notifications for user
export async function GET(request: NextRequest) {
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

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '20');
    const filter = searchParams.get('filter') || 'all'; // all, unread, read

    const skip = (page - 1) * limit;

    let query: any = { userId: decoded.userId };
    
    if (filter === 'unread') {
      query.isRead = false;
    } else if (filter === 'read') {
      query.isRead = true;
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({ 
      userId: decoded.userId, 
      isRead: false 
    });

    return NextResponse.json({
      notifications,
      pagination: {
        page,
        limit,
        total,
        hasMore: skip + notifications.length < total,
      },
      unreadCount,
    });
  } catch (error: any) {
    console.error('Error fetching notifications:', error);
    return NextResponse.json(
      { error: 'Failed to fetch notifications' },
      { status: 500 }
    );
  }
}

// POST - Create notification (for system/admin use)
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

    const body = await request.json();
    const { userId, title, body: notificationBody, type } = body;

    const notification = await Notification.create({
      userId: userId || decoded.userId,
      title,
      body: notificationBody,
      type,
      isRead: false,
    });

    return NextResponse.json(notification, { status: 201 });
  } catch (error: any) {
    console.error('Error creating notification:', error);
    return NextResponse.json(
      { error: 'Failed to create notification' },
      { status: 500 }
    );
  }
}
