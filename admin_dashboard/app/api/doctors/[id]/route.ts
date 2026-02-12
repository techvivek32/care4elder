import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import CallRequest from '@/models/CallRequest';
import WithdrawalRequest from '@/models/WithdrawalRequest';
import { verifyToken } from '@/lib/auth-utils';
import mongoose from 'mongoose';

import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { getToken } from "next-auth/jwt";

const getAuthUser = async (request: Request) => {
  try {
    // 1. Check for NextAuth session (Admin Dashboard)
    const session = await getServerSession(authOptions);
    if (session?.user) {
      return { 
        id: (session.user as any).id, 
        role: (session.user as any).role || 'admin' 
      };
    }

    // 2. Check for NextAuth token
    const token = await getToken({ 
      req: request as any, 
      secret: process.env.NEXTAUTH_SECRET 
    });
    if (token) {
      return {
        id: token.id as string,
        role: (token.role as string) || 'admin'
      };
    }

    // 3. Fallback: Check for Bearer token (Mobile App)
    const authHeader = request.headers.get('authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const bearerToken = authHeader.split(' ')[1];
      const decoded = verifyToken(bearerToken);
      if (decoded && typeof decoded === 'object') {
        return decoded as { id?: string; role?: string };
      }
    }
  } catch (error) {
    console.error('Auth verification error:', error);
  }
  return null;
};

export async function GET(
  request: Request,
  props: { params: Promise<{ id: string }> }
) {
  try {
    await dbConnect();
    const { id } = await props.params;
    const authUser = await getAuthUser(request);

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

    // Get total completed consultations count
    const completedCalls = await CallRequest.find({
      doctorId: id,
      status: 'completed'
    });
    
    const totalConsultations = completedCalls.length;

    // Recalculate wallet balance to ensure it's accurate
    const totalEarnings = completedCalls.reduce((sum, call) => {
      return sum + (call.baseFee || call.fee || 0);
    }, 0);

    const creditedWithdrawals = await WithdrawalRequest.find({
      doctorId: id,
      status: { $in: ['credited', 'approved', 'pending'] }
    });

    const totalWithdrawn = creditedWithdrawals.reduce((sum, req) => {
      return sum + (req.amount || 0);
    }, 0);

    const calculatedBalance = Math.max(0, totalEarnings - totalWithdrawn);

    // Update doctor's wallet balance if it's different
    if (doctor.walletBalance !== calculatedBalance) {
      doctor.walletBalance = calculatedBalance;
      await doctor.save();
      console.log(`Synced doctor ${id} wallet balance to ${calculatedBalance}`);
    }

    const doctorObj = doctor.toObject();
    return NextResponse.json({
      ...doctorObj,
      totalConsultations
    });
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
    const authUser = await getAuthUser(request);

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
    if (body.status != null) {
      updateData.status = body.status;
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
