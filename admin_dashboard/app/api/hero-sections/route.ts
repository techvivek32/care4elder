import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import HeroSection from '@/models/HeroSection';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const type = searchParams.get('type');
    const activeOnly = searchParams.get('activeOnly') === 'true';

    await dbConnect();
    
    let query: any = {};
    if (activeOnly) {
      query.isActive = true;
    }
    if (type && type !== 'both') {
      query.$or = [{ type: type }, { type: 'both' }];
    }

    const heroes = await HeroSection.find(query).sort({ order: 1 });
    return NextResponse.json(heroes);
  } catch (error) {
    console.error('Fetch Hero Section Error:', error);
    return NextResponse.json({ error: 'Failed to fetch hero sections' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    await dbConnect();
    const body = await request.json();
    const hero = await HeroSection.create(body);
    return NextResponse.json(hero);
  } catch (error) {
    console.error('Create Hero Section Error:', error);
    return NextResponse.json({ error: 'Failed to create hero section' }, { status: 500 });
  }
}
