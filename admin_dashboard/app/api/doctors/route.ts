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
    
    const formData = await request.formData();
    
    console.log('Form data received:', {
      fullName: formData.get('fullName'),
      email: formData.get('email'),
      phone: formData.get('phone'),
      specialization: formData.get('specialization'),
      qualifications: formData.get('qualifications')
    });
    
    // Extract form fields
    const fullName = formData.get('fullName') as string;
    const email = formData.get('email') as string;
    const phone = formData.get('phone') as string;
    const idNumber = formData.get('idNumber') as string;
    const password = formData.get('password') as string;
    const licenseNumber = formData.get('licenseNumber') as string;
    const specialization = formData.get('specialization') as string;
    const qualifications = formData.get('qualifications') as string;
    const experience = formData.get('experience') as string;
    const hospitalAddress = formData.get('hospitalAddress') as string;
    
    // Validate required fields
    if (!fullName || !email || !phone || !idNumber || !password || !licenseNumber || !specialization || !qualifications || !experience || !hospitalAddress) {
      return NextResponse.json({ error: 'All fields are required' }, { status: 400 });
    }
    
    // Validate experience is a valid number
    const experienceNum = parseInt(experience);
    if (isNaN(experienceNum) || experienceNum < 0) {
      return NextResponse.json({ error: 'Experience must be a valid positive number' }, { status: 400 });
    }
    
    // Check if doctor already exists
    const existingDoctor = await Doctor.findOne({
      $or: [{ email }, { phone }, { licenseNumber }]
    });
    
    if (existingDoctor) {
      return NextResponse.json({ error: 'Doctor with this email, phone, or license number already exists' }, { status: 400 });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);
    
    // Handle file uploads (for now, we'll store file names - in production, upload to cloud storage)
    const medicalCertificate = formData.get('medicalCertificate') as File;
    const idProof = formData.get('idProof') as File;
    
    const documents = [];
    if (medicalCertificate && medicalCertificate.name) {
      documents.push(medicalCertificate.name);
    }
    if (idProof && idProof.name) {
      documents.push(idProof.name);
    }
    
    console.log('Documents array:', documents);
    
    // Create new doctor
    const newDoctor = new Doctor({
      name: fullName,
      email,
      phone,
      password: hashedPassword,
      idNumber,
      licenseNumber,
      specialization,
      qualifications,
      experienceYears: experienceNum,
      hospitalAffiliation: hospitalAddress,
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
