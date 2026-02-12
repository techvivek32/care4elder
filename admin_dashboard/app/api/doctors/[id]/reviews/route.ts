import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import CallRequest from '@/models/CallRequest';
import Patient from '@/models/Patient';
import mongoose from 'mongoose';

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return NextResponse.json({ error: 'Invalid Doctor ID' }, { status: 400 });
    }

    // Fetch all completed call requests for this doctor that have a rating
    const reviews = await CallRequest.find({
      doctorId: id,
      rating: { $exists: true, $ne: null },
    })
      .populate('patientId', 'name profilePictureUrl')
      .sort({ createdAt: -1 });

    return NextResponse.json(reviews);
  } catch (error) {
    console.error('Fetch Doctor Reviews Error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch reviews' },
      { status: 500 }
    );
  }
}
