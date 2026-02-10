import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import CallRequest from '@/models/CallRequest';
import { verifyToken } from '@/lib/auth-utils';

const getAuthUser = (request: Request) => {
  const authHeader = request.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.split(' ')[1];
  const decoded = verifyToken(token);
  if (!decoded || typeof decoded !== 'object') {
    return null;
  }
  return decoded as { id?: string; role?: string };
};

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const authUser = getAuthUser(request);
    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const callRequest = await CallRequest.findById(id)
      .populate('patientId', 'name')
      .populate('doctorId', 'name');

    if (!callRequest) {
      return NextResponse.json({ error: 'Call request not found' }, { status: 404 });
    }

    // Handle populated fields safely
    const patientId = (callRequest.patientId as any)._id?.toString() || callRequest.patientId.toString();
    const doctorId = (callRequest.doctorId as any)._id?.toString() || callRequest.doctorId.toString();

    if (
      authUser.id !== patientId &&
      authUser.id !== doctorId
    ) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    return NextResponse.json(callRequest);
  } catch (error) {
    console.error('Fetch Call Request Error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch call request' },
      { status: 500 }
    );
  }
}

export async function PATCH(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const authUser = getAuthUser(request);
    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { status, duration, report } = await request.json();
    
    // Allow updating report separately or with status
    if (status && !['accepted', 'declined', 'cancelled', 'timeout', 'ringing', 'completed'].includes(status)) {
      return NextResponse.json({ error: 'Invalid status' }, { status: 400 });
    }

    const callRequest = await CallRequest.findById(id);
    if (!callRequest) {
      return NextResponse.json({ error: 'Call request not found' }, { status: 404 });
    }

    if (
      authUser.id !== callRequest.patientId.toString() &&
      authUser.id !== callRequest.doctorId.toString()
    ) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    if (status) callRequest.status = status;
    if (duration !== undefined) callRequest.duration = duration;
    if (report !== undefined) callRequest.report = report;
    
    await callRequest.save();

    const populated = await CallRequest.findById(id)
      .populate('patientId', 'name')
      .populate('doctorId', 'name');

    return NextResponse.json(populated);
  } catch (error) {
    console.error('Update Call Request Error:', error);
    return NextResponse.json(
      { error: 'Failed to update call request' },
      { status: 500 }
    );
  }
}
