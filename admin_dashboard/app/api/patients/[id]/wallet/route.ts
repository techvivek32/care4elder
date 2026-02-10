import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Patient from '@/models/Patient';
import Setting from '@/models/Setting';
import Transaction from '@/models/Transaction';
import Razorpay from 'razorpay';

export async function POST(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();

    // Fetch Settings
    const settings = await Setting.findOne();
    if (!settings || !settings.razorpayKeyId || !settings.razorpayKeySecret) {
      return NextResponse.json(
        { error: 'Payment gateway not configured' },
        { status: 503 } // Service Unavailable
      );
    }

    const razorpay = new Razorpay({
      key_id: settings.razorpayKeyId,
      key_secret: settings.razorpayKeySecret,
    });

    const { id } = await props.params;
    const { paymentId, amount } = await request.json();

    if (!paymentId || !amount) {
      return NextResponse.json(
        { error: 'Missing paymentId or amount' },
        { status: 400 }
      );
    }

    // Verify payment with Razorpay
    const payment = await razorpay.payments.fetch(paymentId);

    if (!payment) {
        return NextResponse.json({ error: 'Invalid Payment ID' }, { status: 400 });
    }

    if (payment.status !== 'captured' && payment.status !== 'authorized') {
      return NextResponse.json(
        { error: `Payment status is ${payment.status}` },
        { status: 400 }
      );
    }

    // Check amount match (Razorpay amount is in paise)
    // We allow a small epsilon for float comparison if needed, but integer paise comparison is best.
    const amountInRupees = parseFloat(amount);
    const amountInPaise = Math.round(amountInRupees * 100);

    // Note: payment.amount is usually a number or string
    if (Number(payment.amount) !== amountInPaise) {
       return NextResponse.json(
        { error: 'Payment amount mismatch' },
        { status: 400 }
       );
    }

    // Update User Wallet
    const patient = await Patient.findById(id);
    if (!patient) {
      return NextResponse.json({ error: 'Patient not found' }, { status: 404 });
    }

    // Initialize walletBalance if undefined
    if (patient.walletBalance === undefined) {
      patient.walletBalance = 0;
    }

    patient.walletBalance += amountInRupees;
    await patient.save();

    // Create Transaction Record
    await Transaction.create({
      patientId: patient._id,
      type: 'credit',
      amount: amountInRupees,
      description: 'Wallet Recharge',
      paymentId: paymentId,
      balanceAfter: patient.walletBalance
    });

    return NextResponse.json({
      success: true,
      newBalance: patient.walletBalance,
    });
  } catch (error) {
    console.error('Wallet Recharge Error:', error);
    return NextResponse.json(
      { error: 'Failed to recharge wallet' },
      { status: 500 }
    );
  }
}
