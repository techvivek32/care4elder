import { notFound } from 'next/navigation';
import dbConnect from '@/lib/db';
import Doctor from '@/models/Doctor';
import CallRequest from '@/models/CallRequest';
import WithdrawalRequest from '@/models/WithdrawalRequest';
import { 
  User, Phone, Mail, FileText, Calendar, Briefcase, 
  Award, CreditCard, Activity, CheckCircle, XCircle, Clock,
  BarChart
} from 'lucide-react';
import Link from 'next/link';
import WithdrawalRequestsManager from '@/components/WithdrawalRequestsManager';
import DocumentViewer from '@/components/DocumentViewer';
import DoctorEditSections from '@/components/DoctorEditSections';

async function getDoctor(id: string) {
  await dbConnect();
  try {
    const doctor = await Doctor.findById(id);
    if (!doctor) return null;
    
    // Get total completed consultations count
    const completedCalls = await CallRequest.find({
      doctorId: id,
      status: 'completed'
    });
    
    console.log(`Diagnostic for doctor ${id}: Found ${completedCalls.length} completed calls`);
    completedCalls.forEach((call, index) => {
      console.log(`Call ${index}: baseFee=${call.baseFee}, fee=${call.fee}`);
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
    }

    return {
      ...JSON.parse(JSON.stringify(doctor.toObject())),
      totalConsultations
    };
  } catch (error) {
    console.error('Error fetching doctor:', error);
    return null;
  }
}

export default async function DoctorDetailsPage(props: { params: Promise<{ id: string }> }) {
  const params = await props.params;
  const doctor = await getDoctor(params.id);

  if (!doctor) {
    notFound();
  }

  const StatusBadge = ({ status }: { status: string }) => {
    const styles = {
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      pending: 'bg-yellow-100 text-yellow-800'
    };
    const icons = {
      approved: CheckCircle,
      rejected: XCircle,
      pending: Clock
    };
    const Icon = icons[status as keyof typeof icons] || Clock;
    
    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${styles[status as keyof typeof styles] || styles.pending}`}>
        <Icon className="w-4 h-4 mr-2" />
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const resolveImageUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    
    // Ensure leading slash
    const cleanUrl = url.startsWith('/') ? url : `/${url}`;
    
    // If it doesn't already have /uploads/, add it
    if (!cleanUrl.startsWith('/uploads/')) {
      return `/uploads${cleanUrl}`;
    }
    
    return cleanUrl;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Doctor Details</h1>
        <Link 
          href="/dashboard/doctors"
          className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors"
        >
          Back to List
        </Link>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Editable Sections - Main Info, Documents, Financial */}
        <div className="lg:col-span-2 space-y-6">
          <DoctorEditSections doctor={doctor} />

          {/* Withdrawal Requests Section */}
          <WithdrawalRequestsManager doctorId={doctor._id} />
        </div>


        {/* Sidebar Info */}
        <div className="space-y-6">
          {/* Financial Info */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <CreditCard className="w-5 h-5 mr-2 text-green-500" />
              Financial Details
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center py-2 border-b">
                <span className="text-gray-500">Consultation Fee</span>
                <span className="font-semibold text-gray-900">₹{doctor.consultationFee}</span>
              </div>
              <div className="flex justify-between items-center py-2 border-b">
                <span className="text-gray-500">Emergency Fee</span>
                <span className="font-semibold text-gray-900">
                  {doctor.consultationFees?.emergency ? `₹${doctor.consultationFees.emergency}` : '-'}
                </span>
              </div>
              <div className="flex justify-between items-center py-2 border-b">
                <span className="text-gray-500">Wallet Balance</span>
                <span className="font-semibold text-green-600">₹{Number(doctor.walletBalance).toFixed(2)}</span>
              </div>
              
              {doctor.bankDetails && (
                <div className="mt-4 pt-4 border-t bg-gray-50 p-3 rounded-lg">
                  <h4 className="text-sm font-bold text-black mb-3 border-b pb-1">Bank Information</h4>
                  <div className="space-y-3 text-sm">
                    {doctor.bankDetails.bankName && (
                      <div className="flex justify-between border-b border-gray-200 pb-1">
                        <span className="text-gray-700 font-semibold">Bank Name</span>
                        <span className="text-black font-bold">{doctor.bankDetails.bankName}</span>
                      </div>
                    )}
                    <div className="flex justify-between border-b border-gray-200 pb-1">
                      <span className="text-gray-700 font-semibold">Holder Name</span>
                      <span className="text-black font-bold">{doctor.bankDetails.accountHolderName || '-'}</span>
                    </div>
                    <div className="flex justify-between border-b border-gray-200 pb-1">
                      <span className="text-gray-700 font-semibold">Account No</span>
                      <span className="text-black font-bold font-mono tracking-tight">{doctor.bankDetails.accountNumber || '-'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-700 font-semibold">IFSC Code</span>
                      <span className="text-black font-bold font-mono tracking-tight">{doctor.bankDetails.ifscCode || '-'}</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* System Info */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <Activity className="w-5 h-5 mr-2 text-purple-500" />
              System Info
            </h3>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Total Consultations</span>
                <span className="font-semibold text-blue-600">
                  {doctor.totalConsultations || 0}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Joined Date</span>
                <span className="text-gray-900">
                  {new Date(doctor.createdAt).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Last Updated</span>
                <span className="text-gray-900">
                  {new Date(doctor.updatedAt).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-500">Email Verified</span>
                {doctor.isEmailVerified ? (
                  <CheckCircle className="w-4 h-4 text-green-500" />
                ) : (
                  <XCircle className="w-4 h-4 text-red-500" />
                )}
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-500">Availability</span>
                <span className={`px-2 py-0.5 rounded text-xs ${doctor.isAvailable ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                  {doctor.isAvailable ? 'Available' : 'Unavailable'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
