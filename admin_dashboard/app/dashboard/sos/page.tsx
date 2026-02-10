'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { AlertOctagon, CheckCircle, MapPin, ExternalLink, Trash2 } from 'lucide-react';

async function fetchActiveSOS() {
  const res = await fetch('/api/sos');
  if (!res.ok) throw new Error('Failed to fetch SOS alerts');
  return res.json();
}

async function resolveSOS(id: string) {
  const res = await fetch('/api/sos', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, status: 'resolved' }),
  });
  if (!res.ok) throw new Error('Failed to resolve alert');
  return res.json();
}

async function deleteSOS(id: string) {
  const res = await fetch(`/api/sos/${id}`, {
    method: 'DELETE',
  });
  if (!res.ok) throw new Error('Failed to delete alert');
  return res.json();
}

export default function SOSPage() {
  const queryClient = useQueryClient();
  const { data: alerts, isLoading, error } = useQuery({
    queryKey: ['active-sos'],
    queryFn: fetchActiveSOS,
    refetchInterval: 5000, // Real-time polling
  });

  const resolveMutation = useMutation({
    mutationFn: resolveSOS,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['active-sos'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: deleteSOS,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['active-sos'] });
    }
  });

  if (isLoading) return <div>Loading alerts...</div>;
  if (error) return <div>Error loading alerts</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-800 flex items-center">
        <AlertOctagon className="mr-2 h-8 w-8 text-red-600" /> SOS Alerts Management
      </h1>
      
      <div className="space-y-4">
        {alerts.length === 0 ? (
          <div className="bg-gray-50 p-4 rounded-md text-gray-700">No alerts found.</div>
        ) : (
          alerts.map((alert: any) => {
            const isResolved = alert.status === 'resolved';
            return (
              <div 
                key={alert._id} 
                className={`border-l-4 p-4 shadow-sm rounded-r-md flex flex-col md:flex-row justify-between items-start ${
                  isResolved ? 'bg-green-50 border-green-500' : 'bg-red-50 border-red-500'
                }`}
              >
                <div className="mb-4 md:mb-0">
                  <div className="flex items-center gap-3">
                    <h3 className={`text-lg font-bold ${isResolved ? 'text-green-800' : 'text-red-800'}`}>
                      {isResolved ? 'Resolved Alert' : 'Active Emergency'}
                    </h3>
                    <span className={`px-2 py-1 rounded-full text-xs font-bold uppercase tracking-wide ${
                      isResolved ? 'bg-green-200 text-green-800' : 'bg-red-200 text-red-800 animate-pulse'
                    }`}>
                      {alert.status}
                    </span>
                  </div>
                  
                  <p className={`text-sm mt-2 ${isResolved ? 'text-green-700' : 'text-red-700'}`}>
                    <span className="font-semibold">Patient:</span> {alert.patientId?.name || 'Unknown'} <br/>
                    <span className="font-semibold">Phone:</span> {alert.patientId?.phone || 'N/A'} <br/>
                    <span className="font-semibold">Time:</span> {new Date(alert.timestamp).toLocaleString()}
                  </p>
                  <div className="mt-2 text-sm text-gray-600 flex items-center">
                     <MapPin className="h-4 w-4 mr-1" /> Location: {typeof alert.location === 'string' ? alert.location : JSON.stringify(alert.location)}
                  </div>
                </div>
                
                <div className="flex flex-col space-y-2 w-full md:w-auto">
                  <Link
                    href={`/dashboard/sos/${alert._id}`}
                    className="bg-blue-600 text-white px-4 py-2 rounded-md shadow-sm hover:bg-blue-700 flex items-center justify-center transition-colors"
                  >
                    <ExternalLink className="mr-2 h-4 w-4" /> View Details
                  </Link>
                  
                  {!isResolved ? (
                    <button
                      onClick={() => resolveMutation.mutate(alert._id)}
                      className="bg-white text-green-600 px-4 py-2 border border-green-200 rounded-md shadow-sm hover:bg-green-50 flex items-center justify-center transition-colors"
                    >
                      <CheckCircle className="mr-2 h-4 w-4" /> Mark Resolved
                    </button>
                  ) : (
                    <button disabled className="bg-gray-100 text-gray-400 px-4 py-2 border border-gray-200 rounded-md shadow-sm flex items-center justify-center cursor-not-allowed">
                      <CheckCircle className="mr-2 h-4 w-4" /> Resolved
                    </button>
                  )}
                  
                  <button
                    onClick={() => {
                      if (confirm('Are you sure you want to delete this alert?')) {
                        deleteMutation.mutate(alert._id);
                      }
                    }}
                    className="bg-white text-gray-600 px-4 py-2 border border-gray-200 rounded-md shadow-sm hover:bg-gray-100 flex items-center justify-center transition-colors"
                  >
                    <Trash2 className="mr-2 h-4 w-4" /> Delete
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
