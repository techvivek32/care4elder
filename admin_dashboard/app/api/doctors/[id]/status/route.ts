import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';

export async function PUT(
  req: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const { status } = await req.json();

    const verificationStatuses = ['pending', 'approved', 'rejected'];
    const liveStatuses = ['online', 'busy', 'offline'];

    let updateData: any = {};
    if (verificationStatuses.includes(status)) {
      updateData = { verificationStatus: status };
    } else if (liveStatuses.includes(status)) {
      updateData = { status: status };
    } else {
      return NextResponse.json({ error: 'Invalid status' }, { status: 400 });
    }

    const doctor = await Doctor.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    );

    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    return NextResponse.json(doctor);
  } catch (error) {
    console.error('Error updating doctor status:', error);
    return NextResponse.json(
      { error: 'Failed to update doctor status' },
      { status: 500 }
    );
  }
}

export async function PATCH(
  req: Request,
  props: { params: Promise<{ id: string }> }
) {
  return PUT(req, props);
}
