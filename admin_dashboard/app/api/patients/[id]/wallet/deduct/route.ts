import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';

export async function POST(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const { amount } = await request.json();

    if (!amount || amount <= 0) {
      return NextResponse.json(
        { error: 'Invalid amount' },
        { status: 400 }
      );
    }

    const patient = await Patient.findById(id);
    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    const currentBalance = patient.walletBalance || 0;

    if (currentBalance < amount) {
      return NextResponse.json(
        { 
            error: 'Insufficient balance',
            currentBalance: currentBalance,
            required: amount
        },
        { status: 400 }
      );
    }

    patient.walletBalance = currentBalance - amount;
    await patient.save();

    return NextResponse.json({
      success: true,
      newBalance: patient.walletBalance,
      message: 'Amount deducted successfully'
    });
  } catch (error) {
    console.error('Wallet Deduct Error:', error);
    return NextResponse.json(
      { error: 'Failed to process transaction' },
      { status: 500 }
    );
  }
}
