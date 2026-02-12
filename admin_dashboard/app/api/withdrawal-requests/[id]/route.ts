import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import WithdrawalRequest from '@/models/WithdrawalRequest';
import Doctor from '@/models/Doctor';
import { verifyToken } from '@/lib/auth-utils';
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { getToken } from "next-auth/jwt";

const getAuthUser = async (request: Request) => {
  try {
    // 1. Try NextAuth Token (Most reliable for App Router API routes)
    const secret = process.env.NEXTAUTH_SECRET;
    const token = await getToken({ 
      req: request as any, 
      secret: secret 
    });

    if (token) {
      console.log('Auth via Token success:', token.id, token.role);
      return {
        id: token.id as string,
        role: (token.role as string) || 'admin'
      };
    }

    // 2. Try NextAuth Session (Fallback for some environments)
    const session = await getServerSession(authOptions);
    if (session?.user) {
      console.log('Auth via Session success:', (session.user as any).id, (session.user as any).role);
      return { 
        id: (session.user as any).id, 
        role: (session.user as any).role || 'admin' 
      };
    }

    // 3. Try Bearer Token (For Mobile App)
    const authHeader = request.headers.get('authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const bearerToken = authHeader.split(' ')[1];
      const decoded = verifyToken(bearerToken);
      if (decoded && typeof decoded === 'object') {
        console.log('Auth via Bearer success:', (decoded as any).id, (decoded as any).role);
        return decoded as { id?: string; role?: string };
      }
    }
    
    console.log('All auth methods failed for Withdrawal Request [id].');
  } catch (error) {
    console.error('Auth verification error:', error);
  }

  return null;
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

    const oldStatus = withdrawalRequest.status;

    // Handle transitions
    if (status === 'credited' && oldStatus !== 'approved' && oldStatus !== 'pending') {
        return NextResponse.json({ error: 'Request must be approved or pending before it can be marked as credited' }, { status: 400 });
    }

    // Logic for status change
    if (status === 'declined' && oldStatus !== 'declined') {
        // If declined, REFUND the money back to the wallet
        doctor.walletBalance += withdrawalRequest.amount;
        await doctor.save();
        console.log(`Refunded ${withdrawalRequest.amount} to doctor ${doctor._id} because withdrawal was declined.`);
    } else if (status === 'credited' && oldStatus === 'pending') {
        // If moved directly from pending to credited (admin skipping approved step)
        // Balance was already subtracted during POST, so we don't subtract again.
        console.log(`Withdrawal ${id} marked as credited directly from pending.`);
    } else if (status === 'approved' && oldStatus === 'pending') {
        // Keep money subtracted (it was already subtracted during POST)
        console.log(`Withdrawal ${id} approved. Balance remains subtracted.`);
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
