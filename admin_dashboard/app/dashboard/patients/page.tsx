'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Users, Phone, CheckCircle, XCircle, Trash2 } from 'lucide-react';
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

async function deletePatients(ids: string[]) {
  const res = await fetch('/api/patients', {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ids }),
  });
  if (!res.ok) throw new Error('Failed to delete patients');
  return res.json();
}

export default function PatientsPage() {
  const queryClient = useQueryClient();
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

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

  const deleteMutation = useMutation({
    mutationFn: deletePatients,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['patients'] });
      setSelectedIds([]);
    },
  });

  const handleSelectAll = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.checked) {
      setSelectedIds(patients.map((p: any) => p._id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectPatient = (id: string) => {
    setSelectedIds(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  const handleDeleteSelected = () => {
    if (window.confirm(`Are you sure you want to delete ${selectedIds.length} patients?`)) {
      deleteMutation.mutate(selectedIds);
    }
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading patients</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Patient Management</h1>
        {selectedIds.length > 0 && (
          <button
            onClick={handleDeleteSelected}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
            disabled={deleteMutation.isPending}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Delete Selected ({selectedIds.length})
          </button>
        )}
      </div>
      
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <div className="px-6 py-3 border-b border-gray-200 bg-gray-50 flex items-center">
          <input
            type="checkbox"
            className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            checked={patients.length > 0 && selectedIds.length === patients.length}
            onChange={handleSelectAll}
          />
          <span className="ml-3 text-sm font-medium text-gray-700">Select All</span>
        </div>
        <ul className="divide-y divide-gray-200">
          {patients.length === 0 ? (
             <li className="px-6 py-4 text-center text-gray-500">No patients found</li>
          ) : (
            patients.map((patient: any) => (
              <li key={patient._id} className="px-6 py-4 hover:bg-gray-50">
                <div className="flex items-center space-x-4">
                  <input
                    type="checkbox"
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                    checked={selectedIds.includes(patient._id)}
                    onChange={() => handleSelectPatient(patient._id)}
                  />
                  <div className="flex-1 flex items-center justify-between">
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
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  );
}
