import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import RefundRequest from '@/models/RefundRequest';
import { verifyToken } from '@/lib/auth-utils';
import { getServerSession } from 'next-auth/next';
import { authOptions } from '@/lib/auth';
import { getToken } from 'next-auth/jwt';

const getAuthUser = async (request: Request) => {
  try {
    const session = await getServerSession(authOptions);
    if (session?.user) return { id: (session.user as any).id, role: (session.user as any).role || 'admin' };

    const token = await getToken({ req: request as any, secret: process.env.NEXTAUTH_SECRET });
    if (token) return { id: token.id as string, role: (token.role as string) || 'admin' };

    const authHeader = request.headers.get('authorization');
    if (authHeader?.startsWith('Bearer ')) {
      const decoded = verifyToken(authHeader.split(' ')[1]);
      if (decoded && typeof decoded === 'object') return decoded as { id: string; role: string };
    }
  } catch (e) { console.error('Auth error:', e); }
  return null;
};

export async function GET(request: NextRequest) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');

    const query: Record<string, unknown> = {};
    if (authUser.role === 'patient') query.patientId = authUser.id;
    if (status) query.status = status;

    const refunds = await RefundRequest.find(query).sort({ createdAt: -1 });
    return NextResponse.json({ refunds });
  } catch (error) {
    console.error('GET refund-requests error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await request.json();
    const { callRequestId, doctorId, amount, reason, patientName, doctorName } = body;

    if (!callRequestId || !doctorId || !amount || !reason) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const existing = await RefundRequest.findOne({ callRequestId, patientId: authUser.id });
    if (existing) {
      return NextResponse.json({ error: 'Refund request already submitted for this consultation' }, { status: 409 });
    }

    const refund = await RefundRequest.create({
      patientId: authUser.id,
      doctorId,
      callRequestId,
      amount,
      reason,
      patientName,
      doctorName,
      status: 'pending',
    });

    return NextResponse.json({ refund }, { status: 201 });
  } catch (error) {
    console.error('POST refund-requests error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser || authUser.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    const { ids } = await request.json();
    if (!Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json({ error: 'No ids provided' }, { status: 400 });
    }
    await RefundRequest.deleteMany({ _id: { $in: ids } });
    return NextResponse.json({ success: true, deleted: ids.length });
  } catch (error) {
    console.error('DELETE bulk refund-requests error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
