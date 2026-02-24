'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserPlus, Phone, CheckCircle, XCircle, Trash2 } from 'lucide-react';
import Link from 'next/link';
import { useMemo, useState } from 'react';

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

async function bulkDelete(ids: string[]) {
  const res = await fetch('/api/doctors', {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ids }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to delete doctors');
  }
  return res.json();
}

export default function DoctorsPage() {
  const queryClient = useQueryClient();
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [selectAll, setSelectAll] = useState(false);
  
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

  const deleteMutation = useMutation({
    mutationFn: (ids: string[]) => bulkDelete(ids),
    onSuccess: () => {
      setSelected({});
      setSelectAll(false);
      queryClient.invalidateQueries({ queryKey: ['doctors'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  const selectedIds = useMemo(
    () => Object.entries(selected).filter(([, v]) => v).map(([k]) => k),
    [selected]
  );

  const toggleSelectAll = () => {
    if (!doctors || doctors.length === 0) return;
    const value = !selectAll;
    setSelectAll(value);
    const next: Record<string, boolean> = {};
    if (value) {
      doctors.forEach((d: any) => { next[d._id] = true; });
    }
    setSelected(next);
  };

  const toggleOne = (id: string) => {
    setSelected(prev => {
      const next = { ...prev, [id]: !prev[id] };
      return next;
    });
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading doctors</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Doctor Management</h1>
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <div className="px-6 py-3 flex items-center justify-between border-b border-gray-200">
          <label className="inline-flex items-center space-x-2">
            <input
              type="checkbox"
              className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              checked={selectAll}
              onChange={toggleSelectAll}
            />
            <span className="text-sm text-gray-700">Select All</span>
          </label>
          <button
            onClick={() => deleteMutation.mutate(selectedIds)}
            disabled={selectedIds.length === 0 || deleteMutation.isPending}
            className={`inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white ${selectedIds.length === 0 ? 'bg-gray-300 cursor-not-allowed' : 'bg-red-600 hover:bg-red-700'}`}
            title={selectedIds.length === 0 ? 'No selection' : `Delete ${selectedIds.length} selected`}
          >
            <Trash2 className="h-4 w-4 mr-2" /> Delete Selected
          </button>
        </div>
        <ul className="divide-y divide-gray-200">
          {doctors.length === 0 ? (
             <li className="px-6 py-4 text-center text-gray-500">No doctors found</li>
          ) : (
            doctors.map((doctor: any) => (
              <li key={doctor._id} className="px-6 py-4 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center">
                        <input
                          type="checkbox"
                          className="h-4 w-4 mr-3 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                          checked={!!selected[doctor._id]}
                          onChange={() => toggleOne(doctor._id)}
                        />
                        <UserPlus className="h-5 w-5 text-gray-400 mr-2" />
                        <Link href={`/dashboard/doctors/${doctor._id}`} className="hover:underline focus:outline-none">
                          <h3 className="text-lg font-medium text-blue-600 hover:text-blue-800 transition-colors">{doctor.name}</h3>
                        </Link>
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
