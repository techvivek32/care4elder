import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Notification from '@/models/Notification';
import AdminBroadcast from '@/models/AdminBroadcast';
import { getAdminAuthUser } from '@/lib/admin-auth';

const NOTIFICATION_TYPES = ['emergency', 'appointment', 'tip', 'general'] as const;
const AUDIENCES = ['patients', 'doctors', 'both'] as const;

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const auth = await getAdminAuthUser(request);
    if (!auth) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const body = await request.json();
    const title = String(body.title || '').trim();
    const notificationBody = String(body.body || '').trim();
    const type = NOTIFICATION_TYPES.includes(body.type)
      ? body.type
      : 'general';
    const topic = String(body.topic || '').trim();
    const audience = AUDIENCES.includes(body.audience) ? body.audience : null;

    if (!title || !notificationBody) {
      return NextResponse.json(
        { error: 'Title and body are required' },
        { status: 400 }
      );
    }
    if (!audience) {
      return NextResponse.json(
        { error: 'Audience must be patients, doctors, or both' },
        { status: 400 }
      );
    }

    const broadcast = await AdminBroadcast.findByIdAndUpdate(
      id,
      {
        title,
        body: notificationBody,
        type,
        topic,
        audience,
      },
      { new: true }
    );

    if (!broadcast) {
      return NextResponse.json({ error: 'Broadcast not found' }, { status: 404 });
    }

    await Notification.updateMany(
      { 'metadata.broadcastId': id },
      {
        $set: {
          title,
          body: notificationBody,
          type,
          topic,
        },
      }
    );

    return NextResponse.json(broadcast);
  } catch (error) {
    console.error('PATCH admin/notifications/[id] error:', error);
    return NextResponse.json(
      { error: 'Failed to update broadcast' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const auth = await getAdminAuthUser(request);
    if (!auth) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    await Notification.deleteMany({ 'metadata.broadcastId': id });
    const deleted = await AdminBroadcast.findByIdAndDelete(id);
    if (!deleted) {
      return NextResponse.json({ error: 'Broadcast not found' }, { status: 404 });
    }
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('DELETE admin/notifications/[id] error:', error);
    return NextResponse.json(
      { error: 'Failed to delete broadcast' },
      { status: 500 }
    );
  }
}
