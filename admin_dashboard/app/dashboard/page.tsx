'use client';

import { useQuery } from '@tanstack/react-query';
import { Users, UserPlus, Activity, AlertOctagon } from 'lucide-react';

async function fetchStats() {
  const res = await fetch('/api/stats');
  if (!res.ok) throw new Error('Failed to fetch stats');
  return res.json();
}

export default function DashboardPage() {
  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: fetchStats
  });

  if (isLoading) return <div>Loading stats...</div>;
  if (error) return <div>Error loading stats</div>;

  const cards = [
    { name: 'Total Patients', value: stats.totalPatients, icon: Users, color: 'bg-blue-500' },
    { name: 'Total Doctors', value: stats.totalDoctors, icon: UserPlus, color: 'bg-green-500' },
    { name: 'Pending Verifications', value: stats.pendingDoctors, icon: Activity, color: 'bg-yellow-500' },
    { name: 'Active SOS Alerts', value: stats.activeSOS, icon: AlertOctagon, color: 'bg-red-500' },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
      
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <div key={card.name} className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Icon className={`h-6 w-6 text-white p-1 rounded ${card.color}`} />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">{card.name}</dt>
                      <dd className="text-lg font-medium text-gray-900">{card.value}</dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
