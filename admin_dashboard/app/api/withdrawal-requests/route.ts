import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import WithdrawalRequest from '@/models/WithdrawalRequest';
import Doctor from '@/models/Doctor';
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

export async function POST(request: Request) {
  try {
    await dbConnect();
    const authUser = getAuthUser(request);
    if (!authUser?.id || authUser.role !== 'doctor') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { amount } = await request.json();

    if (!amount || amount <= 0) {
      return NextResponse.json({ error: 'Invalid amount' }, { status: 400 });
    }

    const doctor = await Doctor.findById(authUser.id);
    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    if (doctor.walletBalance < amount) {
      return NextResponse.json({ error: 'Insufficient balance' }, { status: 400 });
    }

    if (!doctor.bankDetails || !doctor.bankDetails.accountNumber) {
      return NextResponse.json({ error: 'Bank details not found. Please add bank details in profile.' }, { status: 400 });
    }

    const withdrawalRequest = await WithdrawalRequest.create({
      doctorId: authUser.id,
      amount,
      bankDetails: {
        accountHolderName: doctor.bankDetails.accountHolderName,
        accountNumber: doctor.bankDetails.accountNumber,
        ifscCode: doctor.bankDetails.ifscCode,
      },
      status: 'pending',
    });

    return NextResponse.json(withdrawalRequest);
  } catch (error) {
    console.error('Create Withdrawal Request Error:', error);
    return NextResponse.json({ error: 'Failed to create withdrawal request' }, { status: 500 });
  }
}

export async function GET(request: Request) {
  try {
    await dbConnect();
    const authUser = getAuthUser(request);
    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const doctorId = searchParams.get('doctorId');

    let query: any = {};
    if (authUser.role === 'doctor') {
      query.doctorId = authUser.id;
    } else if (authUser.role === 'admin') {
      if (doctorId) {
        query.doctorId = doctorId;
      }
    } else {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const requests = await WithdrawalRequest.find(query)
      .sort({ createdAt: -1 })
      .populate('doctorId', 'name email phone');

    return NextResponse.json(requests);
  } catch (error) {
    console.error('Fetch Withdrawal Requests Error:', error);
    return NextResponse.json({ error: 'Failed to fetch withdrawal requests' }, { status: 500 });
  }
}
