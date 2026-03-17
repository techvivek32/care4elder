import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Transaction from '@/models/Transaction';

export async function PATCH(
  request: Request,
  props: { params: Promise<{ id: string; txId: string }> }
) {
  try {
    await dbConnect();
    const { txId } = await props.params;
    const { callRequestId } = await request.json();

    if (!callRequestId) {
      return NextResponse.json({ error: 'callRequestId required' }, { status: 400 });
    }

    await Transaction.findByIdAndUpdate(txId, {
      $set: { 'metadata.callRequestId': callRequestId },
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('PATCH transaction error:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
