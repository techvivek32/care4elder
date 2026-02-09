import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';

export async function GET(request: Request) {
  try {
    await dbConnect();
    // Find doctors with wallet balance > 0
    const doctors = await Doctor.find({ walletBalance: { $gt: 0 } }).sort({ walletBalance: -1 });
    return NextResponse.json(doctors);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch payouts' }, { status: 500 });
  }
}

export async function POST(request: Request) {
    try {
        await dbConnect();
        const { doctorId } = await request.json();
        
        const doctor = await Doctor.findById(doctorId);
        if(!doctor) return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });

        // Reset balance
        doctor.walletBalance = 0;
        await doctor.save();
        
        return NextResponse.json({ success: true, message: 'Payout settled' });
    } catch (error) {
        return NextResponse.json({ error: 'Failed to process payout' }, { status: 500 });
    }
}
