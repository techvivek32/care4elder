import { NextRequest, NextResponse } from 'next/server';
import mongoose from 'mongoose';
import dbConnect from '@/lib/db';
import Notification from '@/models/Notification';
import AdminBroadcast from '@/models/AdminBroadcast';
import Patient from '@/models/Patient';
import Doctor from '@/models/Doctor';
import { getAdminAuthUser } from '@/lib/admin-auth';

const NOTIFICATION_TYPES = ['emergency', 'appointment', 'tip', 'general'] as const;
const AUDIENCES = ['patients', 'doctors', 'both'] as const;

async function collectRecipientIds(
  audience: (typeof AUDIENCES)[number]
): Promise<mongoose.Types.ObjectId[]> {
  const ids: mongoose.Types.ObjectId[] = [];
  if (audience === 'patients' || audience === 'both') {
    const rows = await Patient.find({}).select('_id').lean();
    for (const r of rows) {
      ids.push(r._id as mongoose.Types.ObjectId);
    }
  }
  if (audience === 'doctors' || audience === 'both') {
    const rows = await Doctor.find({}).select('_id').lean();
    for (const r of rows) {
      ids.push(r._id as mongoose.Types.ObjectId);
    }
  }
  return ids;
}

export async function GET(request: NextRequest) {
  try {
    await dbConnect();
    const auth = await getAdminAuthUser(request);
    if (!auth) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const broadcasts = await AdminBroadcast.find({})
      .sort({ createdAt: -1 })
      .lean();
    return NextResponse.json(broadcasts);
  } catch (error) {
    console.error('GET admin/notifications error:', error);
    return NextResponse.json(
      { error: 'Failed to list broadcasts' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    await dbConnect();
    const auth = await getAdminAuthUser(request);
    if (!auth) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

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

    const userIds = await collectRecipientIds(audience);
    if (userIds.length === 0) {
      return NextResponse.json(
        { error: 'No recipients found for the selected audience' },
        { status: 400 }
      );
    }

    const broadcast = await AdminBroadcast.create({
      title,
      body: notificationBody,
      type,
      topic,
      audience,
      recipientCount: userIds.length,
    });

    const broadcastId = broadcast._id.toString();
    const BATCH = 400;
    for (let i = 0; i < userIds.length; i += BATCH) {
      const slice = userIds.slice(i, i + BATCH);
      const docs = slice.map((userId) => ({
        userId,
        title,
        body: notificationBody,
        type,
        topic,
        isRead: false,
        metadata: { broadcastId, source: 'admin' },
      }));
      await Notification.insertMany(docs);
    }

    return NextResponse.json(broadcast, { status: 201 });
  } catch (error) {
    console.error('POST admin/notifications error:', error);
    return NextResponse.json(
      { error: 'Failed to send notifications' },
      { status: 500 }
    );
  }
}
