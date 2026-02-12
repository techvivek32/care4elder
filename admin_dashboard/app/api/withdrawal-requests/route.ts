import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import WithdrawalRequest from '@/models/WithdrawalRequest';
import Doctor from '@/models/Doctor';
import { verifyToken } from '@/lib/auth-utils';
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { getToken } from "next-auth/jwt";

const getAuthUser = async (request: Request) => {
  try {
    // 1. Try NextAuth Session (Most reliable for Admin Dashboard)
    const session = await getServerSession(authOptions);
    if (session?.user) {
      console.log('Auth via Session success:', (session.user as any).id, (session.user as any).role);
      return { 
        id: (session.user as any).id, 
        role: (session.user as any).role || 'admin' 
      };
    }

    // 2. Try NextAuth Token (Good for cross-origin/API)
    const token = await getToken({ 
      req: request as any, 
      secret: process.env.NEXTAUTH_SECRET 
    });

    if (token) {
      console.log('Auth via Token success:', token.id, token.role);
      return {
        id: token.id as string,
        role: (token.role as string) || 'admin'
      };
    }

    // 3. Fallback for VPS: Manual cookie parsing
    // This handles cases where getServerSession fails due to proxy/header issues
    const cookieHeader = request.headers.get('cookie') || '';
    if (cookieHeader) {
      const cookies = Object.fromEntries(
        cookieHeader.split(';').map(c => c.trim().split('='))
      );
      
      // Look for any session token (secure or normal)
      const sessionToken = cookies['__Secure-next-auth.session-token'] || cookies['next-auth.session-token'];
      
      if (sessionToken && process.env.NEXTAUTH_SECRET) {
        try {
          // Attempt to decode the token manually if getToken failed
          const decoded = await getToken({
            req: {
              headers: {
                cookie: cookieHeader
              }
            } as any,
            secret: process.env.NEXTAUTH_SECRET,
            raw: false
          });
          
          if (decoded) {
            console.log('Auth via Manual Cookie Decoding success:', decoded.id, decoded.role);
            return {
              id: decoded.id as string,
              role: (decoded.role as string) || 'admin'
            };
          }
        } catch (e) {
          console.error('Manual cookie decoding failed:', e);
        }
      }
    }

    // 4. Try Bearer Token (For Mobile App)
    const authHeader = request.headers.get('authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const bearerToken = authHeader.split(' ')[1];
      const decoded = verifyToken(bearerToken);
      if (decoded && typeof decoded === 'object') {
        console.log('Auth via Bearer success:', (decoded as any).id, (decoded as any).role);
        return decoded as { id?: string; role?: string };
      }
    }
    
    console.log('Auth failed. Host:', request.headers.get('host'), 'Cookies present:', !!cookieHeader);
  } catch (error) {
    console.error('Auth verification error:', error);
  }

  return null;
};

export async function POST(request: Request) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser?.id || authUser.role !== 'doctor') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { amount } = await request.json();

    if (!amount || amount <= 0) {
      return NextResponse.json({ error: 'Invalid amount' }, { status: 400 });
    }

    const doctor = await Doctor.findById(authUser.id);
    if (!doctor) {
      return NextResponse.json({ error: 'Doctor not found' }, { status: 404 });
    }

    if (doctor.walletBalance < amount) {
      return NextResponse.json({ error: 'Insufficient balance' }, { status: 400 });
    }

    if (!doctor.bankDetails || !doctor.bankDetails.accountNumber) {
      return NextResponse.json({ error: 'Bank details not found. Please add bank details in profile.' }, { status: 400 });
    }

    // 1. Create the withdrawal request
    const withdrawalRequest = await WithdrawalRequest.create({
      doctorId: authUser.id,
      amount,
      bankDetails: {
        accountHolderName: doctor.bankDetails.accountHolderName,
        accountNumber: doctor.bankDetails.accountNumber,
        ifscCode: doctor.bankDetails.ifscCode,
      },
      status: 'pending',
    });

    // 2. Immediately subtract from wallet balance when request is made
    doctor.walletBalance -= amount;
    await doctor.save();
    console.log(`Subtracted ${amount} from doctor ${doctor._id} wallet for pending withdrawal. New balance: ${doctor.walletBalance}`);

    return NextResponse.json(withdrawalRequest);
  } catch (error) {
    console.error('Create Withdrawal Request Error:', error);
    return NextResponse.json({ error: 'Failed to create withdrawal request' }, { status: 500 });
  }
}

export async function GET(request: Request) {
  try {
    await dbConnect();
    const authUser = await getAuthUser(request);
    if (!authUser?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const doctorId = searchParams.get('doctorId');

    let query: any = {};
    if (authUser.role === 'doctor') {
      query.doctorId = authUser.id;
    } else if (authUser.role === 'admin') {
      if (doctorId) {
        query.doctorId = doctorId;
      }
    } else {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const requests = await WithdrawalRequest.find(query)
      .sort({ createdAt: -1 })
      .populate('doctorId', 'name email phone');

    return NextResponse.json(requests);
  } catch (error) {
    console.error('Fetch Withdrawal Requests Error:', error);
    return NextResponse.json({ error: 'Failed to fetch withdrawal requests' }, { status: 500 });
  }
}
