import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import * as bcrypt from 'bcryptjs';

export async function GET() {
  try {
    await dbConnect();
    const doctors = await Doctor.find({}).sort({ createdAt: -1 });
    return NextResponse.json(doctors);
  } catch (error) {
    console.error('Error fetching doctors:', error);
    return NextResponse.json(
      { error: 'Failed to fetch doctors' },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    
    // Only admin can add doctors
    const role = (session.user as any).role || 'admin';
    if (role !== 'admin') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    await dbConnect();
    
    console.log('Processing doctor creation request...');
    
    const body = await request.json();
    
    const fullName = body.fullName || '';
    const email = body.email || '';
    const phone = body.phone || '';
    const password = body.password || '';
    const licenseNumber = body.licenseNumber || '';
    const specialization = body.specialization || '';
    const qualifications = body.qualifications || '';
    const experience = body.experience || '';
    const hospitalAddress = body.hospitalAddress || '';
    const profileImage = body.profileImage || null;
    const documents = Array.isArray(body.documents) ? body.documents : [];
    
    // Validate only email format if provided
    if (email && !/\S+@\S+\.\S+/.test(email)) {
      return NextResponse.json({ error: 'Invalid email format' }, { status: 400 });
    }
    
    // Validate experience is a valid number if provided
    const experienceNum = experience ? parseInt(experience) : 0;
    if (experience && (isNaN(experienceNum) || experienceNum < 0)) {
      return NextResponse.json({ error: 'Experience must be a valid positive number' }, { status: 400 });
    }
    
    // Check if doctor already exists (only if email/phone/license provided)
    if (email || phone || licenseNumber) {
      const query: any = { $or: [] };
      if (email) query.$or.push({ email });
      if (phone) query.$or.push({ phone });
      if (licenseNumber) query.$or.push({ licenseNumber });
      
      const existingDoctor = await Doctor.findOne(query);
      
      if (existingDoctor) {
        return NextResponse.json({ error: 'Doctor with this email, phone, or license number already exists' }, { status: 400 });
      }
    }
    
    // Hash password (use default if not provided)
    const hashedPassword = await bcrypt.hash(password || 'Care4Elder@123', 12);
    
    console.log('Documents received:', documents);
    
    // Create new doctor
    const newDoctor = new Doctor({
      name: fullName,
      email,
      phone,
      password: hashedPassword,
      licenseNumber,
      specialization,
      qualifications,
      experienceYears: experienceNum,
      hospitalAffiliation: hospitalAddress,
      profileImage: profileImage || null,
      documents,
      verificationStatus: 'approved', // Admin-added doctors are auto-approved
      isAvailable: true,
      isEmailVerified: true,
      consultationFee: 500, // Default consultation fee
      consultationFees: {
        standard: 500,
        emergency: 800
      },
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    await newDoctor.save();
    
    // Remove password from response
    const doctorResponse = newDoctor.toObject();
    delete doctorResponse.password;
    
    return NextResponse.json(doctorResponse, { status: 201 });
  } catch (error) {
    console.error('Error adding doctor:', error);
    
    // More detailed error logging
    if (error instanceof Error) {
      console.error('Error message:', error.message);
      console.error('Error stack:', error.stack);
    }
    
    // Handle specific MongoDB errors
    if (error && typeof error === 'object' && 'code' in error && error.code === 11000) {
      return NextResponse.json(
        { error: 'Doctor with this email, phone, or license number already exists' },
        { status: 400 }
      );
    }
    
    return NextResponse.json(
      { error: 'Failed to add doctor', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    // Only admin can delete
    const role = (session.user as any).role || 'admin';
    if (role !== 'admin') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    await dbConnect();
    const { ids } = await request.json().catch(() => ({ ids: [] }));
    if (!Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json({ error: 'ids array required' }, { status: 400 });
    }

    const result = await Doctor.deleteMany({ _id: { $in: ids } });
    return NextResponse.json({ deletedCount: result.deletedCount ?? 0 });
  } catch (error) {
    console.error('Bulk delete doctors error:', error);
    return NextResponse.json({ error: 'Failed to delete doctors' }, { status: 500 });
  }
}
