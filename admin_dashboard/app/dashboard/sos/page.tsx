'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { AlertOctagon, CheckCircle, MapPin } from 'lucide-react';

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

export default function SOSPage() {
  const queryClient = useQueryClient();
  const { data: alerts, isLoading, error } = useQuery({
    queryKey: ['active-sos'],
    queryFn: fetchActiveSOS,
    refetchInterval: 5000, // Real-time polling
  });

  const mutation = useMutation({
    mutationFn: resolveSOS,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['active-sos'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    }
  });

  if (isLoading) return <div>Loading alerts...</div>;
  if (error) return <div>Error loading alerts</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-red-600 flex items-center">
        <AlertOctagon className="mr-2 h-8 w-8" /> Active SOS Alerts
      </h1>
      
      <div className="space-y-4">
        {alerts.length === 0 ? (
          <div className="bg-green-50 p-4 rounded-md text-green-700">No active alerts at the moment.</div>
        ) : (
          alerts.map((alert: any) => (
            <div key={alert._id} className="bg-red-50 border-l-4 border-red-500 p-4 shadow-sm rounded-r-md flex justify-between items-start">
              <div>
                <h3 className="text-lg font-bold text-red-800">Emergency Alert</h3>
                <p className="text-sm text-red-700 mt-1">
                  <span className="font-semibold">Patient:</span> {alert.patientId?.name || 'Unknown'} <br/>
                  <span className="font-semibold">Phone:</span> {alert.patientId?.phone || 'N/A'} <br/>
                  <span className="font-semibold">Time:</span> {new Date(alert.timestamp).toLocaleString()}
                </p>
                <div className="mt-2 text-sm text-gray-600 flex items-center">
                   <MapPin className="h-4 w-4 mr-1" /> Location: {JSON.stringify(alert.location)}
                </div>
              </div>
              <button
                onClick={() => mutation.mutate(alert._id)}
                className="bg-white text-red-600 px-4 py-2 border border-red-200 rounded-md shadow-sm hover:bg-red-100 flex items-center"
              >
                <CheckCircle className="mr-2 h-5 w-5" /> Mark Resolved
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
