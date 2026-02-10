'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Users, Phone, CheckCircle, XCircle } from 'lucide-react';
import Link from 'next/link';

async function fetchPatients() {
  const res = await fetch('/api/patients');
  if (!res.ok) throw new Error('Failed to fetch patients');
  return res.json();
}

async function verifyRelative({ id, status }: { id: string; status: boolean }) {
    const res = await fetch(`/api/patients/${id}/verify-relative`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isRelativeVerified: status }),
    });
    if (!res.ok) throw new Error('Failed to update status');
    return res.json();
}

export default function PatientsPage() {
  const queryClient = useQueryClient();

  const { data: patients, isLoading, error } = useQuery({
    queryKey: ['patients'],
    queryFn: fetchPatients
  });

  const mutation = useMutation({
    mutationFn: verifyRelative,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['patients'] });
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading patients</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Patient Management</h1>
      
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {patients.length === 0 ? (
             <li className="px-6 py-4 text-center text-gray-500">No patients found</li>
          ) : (
            patients.map((patient: any) => (
              <li key={patient._id} className="px-6 py-4 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center">
                        <Users className="h-5 w-5 text-gray-400 mr-2" />
                        <Link href={`/dashboard/patients/${patient._id}`} className="hover:underline focus:outline-none">
                            <h3 className="text-lg font-medium text-blue-600 hover:text-blue-800 transition-colors">{patient.name}</h3>
                        </Link>
                    </div>
                    <div className="mt-1 flex items-center text-sm text-gray-500">
                        <Phone className="h-4 w-4 mr-1" />
                        {patient.phone}
                    </div>
                    <div className="mt-2">
                        <p className="text-sm font-medium text-gray-900">Emergency Contacts:</p>
                        <ul className="mt-1 space-y-1">
                            {patient.emergencyContacts && patient.emergencyContacts.map((contact: any, idx: number) => (
                                <li key={idx} className="text-sm text-gray-500">
                                    {contact.name} ({contact.relation}): {contact.phone}
                                </li>
                            ))}
                        </ul>
                    </div>
                  </div>
                  <div className="flex flex-col items-end space-y-2">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      patient.isRelativeVerified ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {patient.isRelativeVerified ? 'Verified' : 'Unverified'}
                    </span>
                    <span className="text-xs text-gray-400">
                        Joined: {new Date(patient.createdAt).toLocaleDateString()}
                    </span>
                    
                    {!patient.isRelativeVerified ? (
                        <button
                            onClick={() => mutation.mutate({ id: patient._id, status: true })}
                            className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                            disabled={mutation.isPending}
                        >
                            <CheckCircle className="h-4 w-4 mr-1" /> Verify Relative
                        </button>
                    ) : (
                        <button
                            onClick={() => mutation.mutate({ id: patient._id, status: false })}
                            className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
                            disabled={mutation.isPending}
                        >
                            <XCircle className="h-4 w-4 mr-1" /> Revoke
                        </button>
                    )}

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
