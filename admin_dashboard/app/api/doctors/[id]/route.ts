import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import { verifyToken } from '@/lib/auth-utils';
import mongoose from 'mongoose';

const getAuthUser = (request: Request) => {
  const authHeader = request.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.split(' ')[1];
  const decoded = verifyToken(token);
  if (!decoded || typeof decoded !== 'object') {
    return null;
  }
  return decoded as { id?: string; role?: string };
};

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const authUser = getAuthUser(request);

    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return NextResponse.json({ error: 'Invalid Doctor ID' }, { status: 400 });
    }

    // Allow public access to doctor details for patients and other users
    // Only restrict if sensitive data needs to be hidden, but for now allow read access
    // if (authUser.role !== 'admin' && authUser.id !== id) {
    //   return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    // }

    const doctor = await Doctor.findById(id);
    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    return NextResponse.json(doctor);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to fetch doctor' }, { status: 500 });
  }
}

export async function PUT(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const authUser = getAuthUser(request);

    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    if (authUser.role !== 'admin' && authUser.id !== id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const body = await request.json();
    const updateData: Record<string, unknown> = {};

    if (body.name != null) updateData.name = body.name;
    if (body.email != null) updateData.email = body.email;
    if (body.phone != null) updateData.phone = body.phone;
    if (body.specialization != null) updateData.specialization = body.specialization;
    if (body.qualifications != null) updateData.qualifications = body.qualifications;
    if (body.experience != null) updateData.experience = body.experience;
    if (body.about != null) updateData.about = body.about;
    if (body.profileImage != null) updateData.profileImage = body.profileImage;
    if (body.consultationFees != null) {
        updateData.consultationFees = body.consultationFees;
        // Also update standard fee as default for compatibility
        if (body.consultationFees.standard) {
             updateData.consultationFee = body.consultationFees.standard;
        }
    }
    if (body.bankDetails != null) {
      updateData.bankDetails = body.bankDetails;
    }

    const doctor = await Doctor.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    return NextResponse.json(doctor);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to update doctor' }, { status: 500 });
  }
}

export async function PATCH(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { status, reason } = await request.json();
    const params = await props.params;
    const id = params.id;

    if (!['approved', 'rejected'].includes(status)) {
       return NextResponse.json({ error: 'Invalid status' }, { status: 400 });
    }

    const updateData: any = { verificationStatus: status };
    if (status === 'rejected' && reason) {
      // You might want to store the rejection reason in the doctor model if schema allows
      // For now we just update status.
    }

    const doctor = await Doctor.findByIdAndUpdate(id, updateData, { new: true });

    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    return NextResponse.json(doctor);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Failed to update doctor' }, { status: 500 });
  }
}
