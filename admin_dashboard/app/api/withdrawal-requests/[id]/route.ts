import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import WithdrawalRequest from '@/models/WithdrawalRequest';
import Doctor from '@/models/Doctor';
import { verifyToken } from '@/lib/auth-utils';
import { getServerSession } from "next-auth/next";
import { authOptions } from "../../auth/[...nextauth]/route";

const getAuthUser = async (request: Request) => {
  // Check for NextAuth session (Admin Dashboard)
  const session = await getServerSession(authOptions);
  if (session?.user) {
    return { 
      id: (session.user as any).id, 
      role: (session.user as any).role || 'admin' 
    };
  }

  // Check for Bearer token (Mobile App)
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

export async function PATCH(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser?.id || authUser.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await props.params;
    const { status, rejectionReason } = await request.json();

    if (!['approved', 'declined', 'credited'].includes(status)) {
      return NextResponse.json({ error: 'Invalid status' }, { status: 400 });
    }

    const withdrawalRequest = await WithdrawalRequest.findById(id);
    if (!withdrawalRequest) {
      return NextResponse.json({ error: 'Withdrawal request not found' }, { status: 404 });
    }

    const doctor = await Doctor.findById(withdrawalRequest.doctorId);
    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    // Handle transitions
    if (status === 'credited' && withdrawalRequest.status !== 'approved') {
        return NextResponse.json({ error: 'Request must be approved before it can be marked as credited' }, { status: 400 });
    }

    if (status === 'credited') {
        // When credited, deduct from wallet balance
        if (doctor.walletBalance < withdrawalRequest.amount) {
            return NextResponse.json({ error: 'Insufficient wallet balance' }, { status: 400 });
        }
        doctor.walletBalance -= withdrawalRequest.amount;
        await doctor.save();
    }

    withdrawalRequest.status = status;
    if (status === 'declined' && rejectionReason) {
      withdrawalRequest.rejectionReason = rejectionReason;
    }
    await withdrawalRequest.save();

    return NextResponse.json(withdrawalRequest);
  } catch (error) {
    console.error('Update Withdrawal Request Error:', error);
    return NextResponse.json({ error: 'Failed to update withdrawal request' }, { status: 500 });
  }
}
