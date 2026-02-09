'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserPlus, Phone, CheckCircle, XCircle, Clock } from 'lucide-react';

async function fetchDoctors() {
  const res = await fetch('/api/doctors');
  if (!res.ok) throw new Error('Failed to fetch doctors');
  return res.json();
}

async function updateStatus({ id, status }: { id: string; status: string }) {
  const res = await fetch(`/api/doctors/${id}/status`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });
  if (!res.ok) throw new Error('Failed to update status');
  return res.json();
}

export default function DoctorsPage() {
  const queryClient = useQueryClient();
  
  const { data: doctors, isLoading, error } = useQuery({
    queryKey: ['doctors'],
    queryFn: fetchDoctors
  });

  const mutation = useMutation({
    mutationFn: updateStatus,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['doctors'] });
      // Also invalidate stats
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading doctors</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Doctor Management</h1>
      
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {doctors.length === 0 ? (
             <li className="px-6 py-4 text-center text-gray-500">No doctors found</li>
          ) : (
            doctors.map((doctor: any) => (
              <li key={doctor._id} className="px-6 py-4 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center">
                        <UserPlus className="h-5 w-5 text-gray-400 mr-2" />
                        <h3 className="text-lg font-medium text-gray-900">{doctor.name}</h3>
                        <span className={`ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          doctor.verificationStatus === 'approved' ? 'bg-green-100 text-green-800' :
                          doctor.verificationStatus === 'rejected' ? 'bg-red-100 text-red-800' :
                          'bg-yellow-100 text-yellow-800'
                        }`}>
                          {doctor.verificationStatus}
                        </span>
                    </div>
                    <div className="mt-1 flex items-center text-sm text-gray-500">
                        <Phone className="h-4 w-4 mr-1" />
                        {doctor.phone} | {doctor.specialization}
                    </div>
                    <div className="mt-1 text-sm text-gray-500">
                        Email: {doctor.email} | License: {doctor.licenseNumber}
                    </div>
                  </div>
                  <div className="flex flex-col items-end space-y-2">
                    <div className="flex space-x-2">
                        {doctor.verificationStatus === 'pending' && (
                            <>
                                <button
                                    onClick={() => mutation.mutate({ id: doctor._id, status: 'approved' })}
                                    className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                                    disabled={mutation.isPending}
                                >
                                    <CheckCircle className="h-4 w-4 mr-1" /> Approve
                                </button>
                                <button
                                    onClick={() => mutation.mutate({ id: doctor._id, status: 'rejected' })}
                                    className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
                                    disabled={mutation.isPending}
                                >
                                    <XCircle className="h-4 w-4 mr-1" /> Reject
                                </button>
                            </>
                        )}
                        {doctor.verificationStatus === 'approved' && (
                             <button
                                onClick={() => mutation.mutate({ id: doctor._id, status: 'rejected' })}
                                className="text-red-600 hover:text-red-900 text-sm"
                                disabled={mutation.isPending}
                            >
                                Revoke
                            </button>
                        )}
                         {doctor.verificationStatus === 'rejected' && (
                             <button
                                onClick={() => mutation.mutate({ id: doctor._id, status: 'approved' })}
                                className="text-green-600 hover:text-green-900 text-sm"
                                disabled={mutation.isPending}
                            >
                                Re-approve
                            </button>
                        )}
                    </div>
                    <span className="text-xs text-gray-400">
                        Joined: {new Date(doctor.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  );
}
