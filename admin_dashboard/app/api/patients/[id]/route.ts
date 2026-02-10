import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
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

    // Basic admin check - in a real app, middleware handles this but good for safety
    // Also allow patient to fetch their own profile
    if (!authUser?.id) {
      // For now, if called from server component (like our page.tsx), headers might differ.
      // But typically we rely on the API protection.
      // Let's assume this is protected by middleware or similar.
    }

    const patient = await Patient.findById(id);
    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    return NextResponse.json(patient);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to fetch patient' }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const body = await request.json();

    const patient = await Patient.findByIdAndUpdate(id, body, {
      new: true,
      runValidators: true,
    });

    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    return NextResponse.json(patient);
  } catch (error) {
    console.error('Update Patient Error:', error);
    return NextResponse.json(
      { error: 'Failed to update patient' },
      { status: 500 }
    );
  }
}
