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
    
    const totalConsultations = completedCalls.length;

    // Recalculate wallet balance to ensure it's accurate
    const totalEarnings = completedCalls.reduce((sum, call) => {
      return sum + (call.baseFee || call.fee || 0);
    }, 0);

    const creditedWithdrawals = await WithdrawalRequest.find({
      doctorId: id,
      status: 'credited'
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
        {/* Main Info Card */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white shadow rounded-lg p-6">
            <div className="flex items-start justify-between mb-6">
              <div className="flex items-center space-x-4">
                {doctor.profileImage ? (
                  <div className="relative w-16 h-16 rounded-full overflow-hidden border-2 border-blue-100">
                    <img 
                      src={resolveImageUrl(doctor.profileImage)} 
                      alt={doctor.name} 
                      className="w-full h-full object-cover"
                    />
                  </div>
                ) : (
                  <div className="bg-blue-100 p-3 rounded-full">
                    <User className="w-8 h-8 text-blue-600" />
                  </div>
                )}
                <div>
                  <h2 className="text-xl font-bold text-gray-900">{doctor.name}</h2>
                  <p className="text-gray-500">{doctor.specialization}</p>
                </div>
              </div>
              <StatusBadge status={doctor.verificationStatus} />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-1">
                <label className="text-sm font-medium text-gray-500">Email</label>
                <div className="flex items-center text-gray-900">
                  <Mail className="w-4 h-4 mr-2 text-gray-400" />
                  {doctor.email}
                </div>
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-gray-500">Phone</label>
                <div className="flex items-center text-gray-900">
                  <Phone className="w-4 h-4 mr-2 text-gray-400" />
                  {doctor.phone}
                </div>
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-gray-500">License Number</label>
                <div className="flex items-center text-gray-900">
                  <Award className="w-4 h-4 mr-2 text-gray-400" />
                  {doctor.licenseNumber}
                </div>
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-gray-500">Experience</label>
                <div className="flex items-center text-gray-900">
                  <Briefcase className="w-4 h-4 mr-2 text-gray-400" />
                  {doctor.experienceYears ? `${doctor.experienceYears} Years` : 'Not specified'}
                </div>
              </div>
            </div>

            <div className="mt-6 space-y-4">
              <div>
                <label className="text-sm font-medium text-gray-500">About</label>
                <p className="mt-1 text-gray-900 whitespace-pre-wrap">{doctor.about || 'No description provided.'}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Qualifications</label>
                <p className="mt-1 text-gray-900">{doctor.qualifications || 'Not specified'}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-500">Hospital Affiliation</label>
                <p className="mt-1 text-gray-900">{doctor.hospitalAffiliation || 'Not specified'}</p>
              </div>
            </div>
          </div>

          {/* Withdrawal Requests Section */}
          <WithdrawalRequestsManager doctorId={doctor._id} />

          {/* Documents Section */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <FileText className="w-5 h-5 mr-2 text-blue-500" />
              Documents
            </h3>
            {doctor.documents && doctor.documents.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                {doctor.documents.map((doc: string, index: number) => (
                  <div key={index} className="space-y-2">
                     <div className="flex items-center justify-between">
                        <p className="text-sm font-medium text-gray-700">Document {index + 1}</p>
                        <a 
                          href={resolveImageUrl(doc)} 
                          target="_blank" 
                          rel="noopener noreferrer"
                          className="text-xs text-blue-600 hover:text-blue-800 flex items-center"
                        >
                          <FileText className="w-3 h-3 mr-1" /> Open full size
                        </a>
                     </div>
                     <div className="border rounded-lg overflow-hidden bg-gray-50 p-2">
                        <img 
                          src={resolveImageUrl(doc)} 
                          alt={`Document ${index + 1}`}
                          className="w-full h-auto object-contain max-h-[500px]"
                        />
                     </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 italic">No documents uploaded.</p>
            )}
          </div>
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
                <span className="font-semibold text-green-600">₹{doctor.walletBalance}</span>
              </div>
              
              {doctor.bankDetails && (
                <div className="mt-4 pt-4 border-t">
                  <h4 className="text-sm font-medium text-gray-900 mb-3">Bank Information</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Holder Name</span>
                      <span className="text-gray-900">{doctor.bankDetails.accountHolderName || '-'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Account No</span>
                      <span className="text-gray-900">{doctor.bankDetails.accountNumber || '-'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">IFSC Code</span>
                      <span className="text-gray-900">{doctor.bankDetails.ifscCode || '-'}</span>
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
