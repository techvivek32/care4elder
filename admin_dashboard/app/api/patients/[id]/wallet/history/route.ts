import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Transaction from '@/models/Transaction';

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;

    const transactions = await Transaction.find({ patientId: id })
      .sort({ createdAt: -1 }) // Newest first
      .limit(20); // Limit to last 20 transactions

    return NextResponse.json(transactions);
  } catch (error) {
    console.error('Wallet History Error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch wallet history' },
      { status: 500 }
    );
  }
}
