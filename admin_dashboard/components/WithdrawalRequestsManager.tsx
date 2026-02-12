'use client';

import { useState, useEffect } from 'react';
import { useSession } from 'next-auth/react';
import { 
  CheckCircle, XCircle, Clock, CreditCard, AlertCircle, 
  ChevronDown, ChevronUp, ExternalLink 
} from 'lucide-react';

interface WithdrawalRequest {
  _id: string;
  amount: number;
  status: 'pending' | 'approved' | 'declined' | 'credited';
  bankDetails: {
    accountHolderName: string;
    accountNumber: string;
    ifscCode: string;
  };
  rejectionReason?: string;
  createdAt: string;
  updatedAt: string;
}

export default function WithdrawalRequestsManager({ doctorId }: { doctorId: string }) {
  const { data: session, status } = useSession();
  const [requests, setRequests] = useState<WithdrawalRequest[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);

  const fetchRequests = async () => {
    if (status !== 'authenticated') {
      setError('You must be logged in to view withdrawal requests');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const response = await fetch(`/api/withdrawal-requests?doctorId=${doctorId}`, {
        cache: 'no-store',
        credentials: 'include', // Ensure cookies are sent
        headers: {
          'Accept': 'application/json',
        }
      });

      if (response.status === 401) {
        throw new Error('Unauthorized: Your session may have expired. Please refresh the page and log in again.');
      }

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error || 'Failed to fetch withdrawal requests');
      }

      const data = await response.json();
      setRequests(data);
    } catch (err) {
      console.error('Fetch error:', err);
      setError(err instanceof Error ? err.message : 'An error occurred while fetching requests');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isOpen) {
      fetchRequests();
    }
  }, [isOpen, doctorId]);

  const handleUpdateStatus = async (id: string, status: string, rejectionReason?: string) => {
    try {
      setProcessingId(id);
      const response = await fetch(`/api/withdrawal-requests/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, rejectionReason }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to update status');
      }

      // Refresh list
      await fetchRequests();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to update status');
    } finally {
      setProcessingId(null);
    }
  };

  const getStatusStyle = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-blue-100 text-blue-800';
      case 'credited': return 'bg-green-100 text-green-800';
      case 'declined': return 'bg-red-100 text-red-800';
      default: return 'bg-yellow-100 text-yellow-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="w-4 h-4 mr-1" />;
      case 'credited': return <CheckCircle className="w-4 h-4 mr-1" />;
      case 'declined': return <XCircle className="w-4 h-4 mr-1" />;
      default: return <Clock className="w-4 h-4 mr-1" />;
    }
  };

  return (
    <div className="bg-white shadow rounded-lg overflow-hidden border border-gray-200">
      <button 
        onClick={() => setIsOpen(!isOpen)}
        className="w-full px-6 py-4 flex items-center justify-between bg-gray-50 hover:bg-gray-100 transition-colors"
      >
        <div className="flex items-center text-gray-900 font-medium">
          <CreditCard className="w-5 h-5 mr-2 text-blue-600" />
          Withdrawal Requests
          {requests.length > 0 && (
            <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
              {requests.length}
            </span>
          )}
        </div>
        {isOpen ? <ChevronUp className="w-5 h-5 text-gray-400" /> : <ChevronDown className="w-5 h-5 text-gray-400" />}
      </button>

      {isOpen && (
        <div className="p-6">
          {loading && requests.length === 0 ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
          ) : error ? (
            <div className="flex items-center text-red-600 py-4">
              <AlertCircle className="w-5 h-5 mr-2" />
              {error}
            </div>
          ) : requests.length === 0 ? (
            <p className="text-center text-gray-500 py-8">No withdrawal requests found for this doctor.</p>
          ) : (
            <div className="space-y-6">
              {requests.map((request) => (
                <div key={request._id} className="border rounded-lg p-4 bg-gray-50 space-y-4">
                  <div className="flex justify-between items-start">
                    <div>
                      <div className="text-2xl font-bold text-gray-900">₹{request.amount}</div>
                      <div className="text-sm text-gray-500">
                        Requested on {new Date(request.createdAt).toLocaleDateString()} at {new Date(request.createdAt).toLocaleTimeString()}
                      </div>
                    </div>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusStyle(request.status)}`}>
                      {getStatusIcon(request.status)}
                      {request.status.charAt(0).toUpperCase() + request.status.slice(1)}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 py-4 border-t border-b border-gray-200 bg-white rounded-md px-3 shadow-sm">
                    <div>
                      <div className="text-xs text-gray-700 uppercase font-bold mb-1">Account Holder</div>
                      <div className="text-base font-bold text-black">{request.bankDetails.accountHolderName}</div>
                    </div>
                    <div>
                      <div className="text-xs text-gray-700 uppercase font-bold mb-1">Account Number</div>
                      <div className="text-base font-bold text-black font-mono tracking-wider">{request.bankDetails.accountNumber}</div>
                    </div>
                    <div>
                      <div className="text-xs text-gray-700 uppercase font-bold mb-1">IFSC Code</div>
                      <div className="text-base font-bold text-black font-mono tracking-wider">{request.bankDetails.ifscCode}</div>
                    </div>
                  </div>

                  {request.rejectionReason && (
                    <div className="bg-red-50 p-3 rounded text-sm text-red-700">
                      <strong>Rejection Reason:</strong> {request.rejectionReason}
                    </div>
                  )}

                  <div className="flex flex-wrap gap-2 pt-2">
                    {request.status === 'pending' && (
                      <>
                        <button
                          disabled={processingId === request._id}
                          onClick={() => handleUpdateStatus(request._id, 'approved')}
                          className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded hover:bg-blue-700 disabled:opacity-50 transition-colors"
                        >
                          Approve
                        </button>
                        <button
                          disabled={processingId === request._id}
                          onClick={() => {
                            const reason = prompt('Enter rejection reason:');
                            if (reason) handleUpdateStatus(request._id, 'declined', reason);
                          }}
                          className="px-4 py-2 bg-red-600 text-white text-sm font-medium rounded hover:bg-red-700 disabled:opacity-50 transition-colors"
                        >
                          Decline
                        </button>
                      </>
                    )}
                    {request.status === 'approved' && (
                      <button
                        disabled={processingId === request._id}
                        onClick={() => {
                          if (confirm('Confirm that you have manually transferred the amount? This will deduct from doctor\'s wallet.')) {
                            handleUpdateStatus(request._id, 'credited');
                          }
                        }}
                        className="px-4 py-2 bg-green-600 text-white text-sm font-medium rounded hover:bg-green-700 disabled:opacity-50 transition-colors flex items-center"
                      >
                        <CheckCircle className="w-4 h-4 mr-1" />
                        Mark as Credited
                      </button>
                    )}
                    {request.status === 'credited' && (
                      <div className="text-green-600 text-sm flex items-center font-medium">
                        <CheckCircle className="w-4 h-4 mr-1" />
                        Payment Completed
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
