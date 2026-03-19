import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import DoctorTransaction from '@/models/DoctorTransaction';
import { verifyToken } from '@/lib/auth-utils';

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const authHeader = request.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    const decoded = verifyToken(authHeader.split(' ')[1]);
    if (!decoded) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const { id } = await props.params;
    const transactions = await DoctorTransaction.find({ doctorId: id }).sort({ createdAt: -1 }).limit(50);
    return NextResponse.json({ transactions });
  } catch (error) {
    console.error('GET doctor transactions error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
