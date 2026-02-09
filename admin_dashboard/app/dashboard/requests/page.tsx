'use client';

import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { CheckCircle, XCircle, FileText } from 'lucide-react';

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

function isImageFile(path: string) {
  return /\.(jpg|jpeg|png|gif|webp)$/i.test(path);
}

function normalizeDocUrl(doc: string) {
  if (doc.startsWith('http')) return doc;
  if (doc.startsWith('/')) return doc;
  return `/${doc}`;
}

export default function RequestsPage() {
  const queryClient = useQueryClient();
  const { data: doctors, isLoading, error } = useQuery({
    queryKey: ['doctors'],
    queryFn: fetchDoctors,
  });

  const pendingDoctors = useMemo(
    () => (doctors ?? []).filter((doc: any) => doc.verificationStatus === 'pending'),
    [doctors],
  );

  const [selectedId, setSelectedId] = useState<string | null>(null);

  useEffect(() => {
    if (pendingDoctors.length === 0) {
      setSelectedId(null);
      return;
    }
    if (!selectedId || !pendingDoctors.find((doc: any) => doc._id === selectedId)) {
      setSelectedId(pendingDoctors[0]._id);
    }
  }, [pendingDoctors, selectedId]);

  const selectedDoctor = pendingDoctors.find((doc: any) => doc._id === selectedId) ?? null;

  const mutation = useMutation({
    mutationFn: updateStatus,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['doctors'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading requests</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">New Requests</h1>
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="px-4 py-3 border-b">
            <div className="text-sm font-semibold text-gray-700">
              Pending Requests ({pendingDoctors.length})
            </div>
          </div>
          <ul className="divide-y divide-gray-200 max-h-[70vh] overflow-y-auto">
            {pendingDoctors.length === 0 ? (
              <li className="px-4 py-6 text-center text-gray-500">No pending requests</li>
            ) : (
              pendingDoctors.map((doctor: any) => (
                <li key={doctor._id}>
                  <button
                    type="button"
                    onClick={() => setSelectedId(doctor._id)}
                    className={`w-full text-left px-4 py-3 hover:bg-gray-50 ${
                      selectedId === doctor._id ? 'bg-blue-50' : ''
                    }`}
                  >
                    <div className="text-sm font-medium text-gray-900">{doctor.name}</div>
                    <div className="text-xs text-gray-500">{doctor.email}</div>
                  </button>
                </li>
              ))
            )}
          </ul>
        </div>

        <div className="bg-white shadow rounded-lg p-6 lg:col-span-2">
          {!selectedDoctor ? (
            <div className="text-center text-gray-500">Select a request to view details</div>
          ) : (
            <div className="space-y-6">
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-xl font-semibold text-gray-900">{selectedDoctor.name}</div>
                  <div className="text-sm text-gray-600">{selectedDoctor.email}</div>
                  <div className="text-sm text-gray-600">{selectedDoctor.phone}</div>
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => mutation.mutate({ id: selectedDoctor._id, status: 'approved' })}
                    className="inline-flex items-center px-3 py-2 text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                    disabled={mutation.isPending}
                  >
                    <CheckCircle className="h-4 w-4 mr-1" />
                    Approve
                  </button>
                  <button
                    onClick={() => mutation.mutate({ id: selectedDoctor._id, status: 'rejected' })}
                    className="inline-flex items-center px-3 py-2 text-xs font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
                    disabled={mutation.isPending}
                  >
                    <XCircle className="h-4 w-4 mr-1" />
                    Reject
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">Specialization</div>
                  <div>{selectedDoctor.specialization ?? 'Not provided'}</div>
                </div>
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">License Number</div>
                  <div>{selectedDoctor.licenseNumber ?? 'Not provided'}</div>
                </div>
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">Experience Years</div>
                  <div>{selectedDoctor.experienceYears ?? 'Not provided'}</div>
                </div>
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">Hospital Affiliation</div>
                  <div>{selectedDoctor.hospitalAffiliation ?? 'Not provided'}</div>
                </div>
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">ID Number</div>
                  <div>{selectedDoctor.idNumber ?? 'Not provided'}</div>
                </div>
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">Consultation Fee</div>
                  <div>{selectedDoctor.consultationFee ?? 'Not provided'}</div>
                </div>
                <div className="text-sm text-gray-700">
                  <div className="text-xs text-gray-500">Submitted On</div>
                  <div>
                    {selectedDoctor.createdAt
                      ? new Date(selectedDoctor.createdAt).toLocaleDateString()
                      : 'Not provided'}
                  </div>
                </div>
              </div>

              <div>
                <div className="text-sm font-semibold text-gray-800 mb-2">Documents</div>
                {selectedDoctor.documents?.length ? (
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    {selectedDoctor.documents.map((doc: string) => {
                      const url = normalizeDocUrl(doc);
                      return (
                        <div
                          key={doc}
                          className="border rounded-lg p-3 flex flex-col items-center justify-center text-sm text-gray-600"
                        >
                          {isImageFile(doc) ? (
                            <img src={url} alt="Document" className="max-h-48 w-full object-contain" />
                          ) : (
                            <a
                              href={url}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex items-center text-blue-600 hover:text-blue-800"
                            >
                              <FileText className="h-4 w-4 mr-1" />
                              Open Document
                            </a>
                          )}
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="text-sm text-gray-500">No documents uploaded</div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
