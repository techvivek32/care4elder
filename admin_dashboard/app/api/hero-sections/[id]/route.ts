import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import HeroSection from '@/models/HeroSection';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await dbConnect();
    const hero = await HeroSection.findById(id);
    if (!hero) {
      return NextResponse.json({ error: 'Hero section not found' }, { status: 404 });
    }
    return NextResponse.json(hero);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch hero section' }, { status: 500 });
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
    const hero = await HeroSection.findByIdAndUpdate(id, body, { new: true });
    if (!hero) {
      return NextResponse.json({ error: 'Hero section not found' }, { status: 404 });
    }
    return NextResponse.json(hero);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update hero section' }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await dbConnect();
    const hero = await HeroSection.findByIdAndDelete(id);
    if (!hero) {
      return NextResponse.json({ error: 'Hero section not found' }, { status: 404 });
    }
    return NextResponse.json({ message: 'Hero section deleted successfully' });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete hero section' }, { status: 500 });
  }
}
