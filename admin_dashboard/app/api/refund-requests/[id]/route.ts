import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import RefundRequest from '@/models/RefundRequest';
import Patient from '@/models/Patient';
import Doctor from '@/models/Doctor';
import Transaction from '@/models/Transaction';
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

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser || authUser.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const body = await request.json();
    const { status, adminNote } = body;

    if (!['approved', 'rejected'].includes(status)) {
      return NextResponse.json({ error: 'Invalid status' }, { status: 400 });
    }

    const refund = await RefundRequest.findById(id);
    if (!refund) return NextResponse.json({ error: 'Refund request not found' }, { status: 404 });
    if (refund.status !== 'pending') {
      return NextResponse.json({ error: 'Refund already processed' }, { status: 400 });
    }

    if (status === 'approved') {
      // 1. Credit patient wallet
      const patient = await Patient.findById(refund.patientId);
      if (patient) {
        patient.walletBalance = (patient.walletBalance || 0) + refund.amount;
        await patient.save();
        await Transaction.create({
          patientId: patient._id,
          type: 'credit',
          amount: refund.amount,
          description: 'Refund',
          balanceAfter: patient.walletBalance,
          metadata: { doctorName: refund.doctorName, refundRequestId: refund._id },
        });
      }

      // 2. Deduct doctor wallet
      const doctor = await Doctor.findById(refund.doctorId);
      if (doctor) {
        doctor.walletBalance = Math.max(0, (doctor.walletBalance || 0) - refund.amount);
        await doctor.save();
      }
    }

    refund.status = status;
    if (adminNote) refund.adminNote = adminNote;
    await refund.save();

    return NextResponse.json({ refund });
  } catch (error) {
    console.error('PATCH refund-requests error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
