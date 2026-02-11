import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import HealthTip from '@/models/HealthTip';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await dbConnect();
    const tip = await HealthTip.findById(id);
    if (!tip) {
      return NextResponse.json({ error: 'Health tip not found' }, { status: 404 });
    }
    return NextResponse.json(tip);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch health tip' }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await dbConnect();
    const body = await request.json();
    const tip = await HealthTip.findByIdAndUpdate(id, body, { new: true });
    if (!tip) {
      return NextResponse.json({ error: 'Health tip not found' }, { status: 404 });
    }
    return NextResponse.json(tip);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update health tip' }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await dbConnect();
    const tip = await HealthTip.findByIdAndDelete(id);
    if (!tip) {
      return NextResponse.json({ error: 'Health tip not found' }, { status: 404 });
    }
    return NextResponse.json({ message: 'Health tip deleted successfully' });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete health tip' }, { status: 500 });
  }
}
