'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { IndianRupee, Check } from 'lucide-react';

async function fetchPayouts() {
  const res = await fetch('/api/doctors/payouts');
  if (!res.ok) throw new Error('Failed to fetch payouts');
  return res.json();
}

async function settlePayout(doctorId: string) {
  const res = await fetch('/api/doctors/payouts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ doctorId }),
  });
  if (!res.ok) throw new Error('Failed to process payout');
  return res.json();
}

export default function PayoutsPage() {
  const queryClient = useQueryClient();
  const { data: doctors, isLoading, error } = useQuery({
    queryKey: ['payouts'],
    queryFn: fetchPayouts
  });

  const mutation = useMutation({
    mutationFn: settlePayout,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payouts'] });
    }
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading payouts</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Pending Payouts</h1>
      
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {doctors.length === 0 ? (
             <li className="px-6 py-4 text-center text-gray-500">No pending payouts</li>
          ) : (
            doctors.map((doctor: any) => (
              <li key={doctor._id} className="px-6 py-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">{doctor.name}</h3>
                    <p className="text-sm text-gray-500">
                      Bank: {doctor.bankDetails?.bankName || 'N/A'} • {doctor.bankDetails?.accountNumber || 'N/A'}
                    </p>
                    <div className="mt-1 flex items-center text-sm text-gray-500">
                       <IndianRupee className="h-4 w-4 text-green-500 mr-1" />
                       <span className="font-bold text-green-600 text-lg">₹{doctor.walletBalance}</span>
                    </div>
                  </div>
                  <button
                    onClick={() => mutation.mutate(doctor._id)}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none"
                  >
                    <Check className="mr-2 h-4 w-4" /> Mark Paid
                  </button>
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  );
}
