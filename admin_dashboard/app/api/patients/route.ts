import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';

export async function GET() {
  try {
    await dbConnect();
    const patients = await Patient.find({}).sort({ createdAt: -1 });
    return NextResponse.json(patients);
  } catch (error) {
    console.error('Error fetching patients:', error);
    return NextResponse.json(
      { error: 'Failed to fetch patients' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: Request) {
  try {
    await dbConnect();
    const { ids } = await request.json();

    if (!ids || !Array.isArray(ids)) {
      return NextResponse.json(
        { error: 'Invalid patient IDs' },
        { status: 400 }
      );
    }

    await Patient.deleteMany({ _id: { $in: ids } });

    return NextResponse.json({ message: 'Patients deleted successfully' });
  } catch (error) {
    console.error('Error deleting patients:', error);
    return NextResponse.json(
      { error: 'Failed to delete patients' },
      { status: 500 }
    );
  }
}
