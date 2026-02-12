'use client';

import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Save, Lock, Key } from 'lucide-react';

async function fetchSettings() {
  const res = await fetch('/api/settings');
  if (!res.ok) throw new Error('Failed to fetch settings');
  return res.json();
}

async function updateSettings(data: { 
  razorpayKeyId: string; 
  razorpayKeySecret: string;
  standardCommission: number;
  emergencyCommission: number;
}) {
  const res = await fetch('/api/settings', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error('Failed to update settings');
  return res.json();
}

export default function SettingsPage() {
  const queryClient = useQueryClient();
  const [formData, setFormData] = useState({
    razorpayKeyId: '',
    razorpayKeySecret: '',
    standardCommission: 0,
    emergencyCommission: 0,
  });
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const { data: settings, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: fetchSettings,
  });

  useEffect(() => {
    if (settings) {
      setFormData({
        razorpayKeyId: settings.razorpayKeyId || '',
        razorpayKeySecret: settings.razorpayKeySecret || '',
        standardCommission: settings.standardCommission || 0,
        emergencyCommission: settings.emergencyCommission || 0,
      });
    }
  }, [settings]);

  const mutation = useMutation({
    mutationFn: updateSettings,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] });
      setMessage({ type: 'success', text: 'Settings updated successfully' });
      setTimeout(() => setMessage(null), 3000);
    },
    onError: (error) => {
      setMessage({ type: 'error', text: 'Failed to update settings' });
      console.error(error);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate(formData);
  };

  if (isLoading) return <div>Loading settings...</div>;

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-2xl font-bold text-black">Settings</h1>

      <div className="bg-white shadow sm:rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-black">Payment Configuration</h3>
          <div className="mt-2 max-w-xl text-sm text-black">
            <p>Configure your Razorpay API keys here.</p>
          </div>
          
          <form onSubmit={handleSubmit} className="mt-5 space-y-4">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label htmlFor="key_id" className="block text-sm font-medium text-black">
                  Razorpay Key ID
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Key className="h-4 w-4 text-black" />
                  </div>
                  <input
                    type="text"
                    name="key_id"
                    id="key_id"
                    className="text-black placeholder-gray-500 focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md p-2 border"
                    placeholder="rzp_test_..."
                    value={formData.razorpayKeyId}
                    onChange={(e) => setFormData({ ...formData, razorpayKeyId: e.target.value })}
                  />
                </div>
              </div>

              <div>
                <label htmlFor="key_secret" className="block text-sm font-medium text-black">
                  Razorpay Key Secret
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-4 w-4 text-black" />
                  </div>
                  <input
                    type="password"
                    name="key_secret"
                    id="key_secret"
                    className="text-black placeholder-gray-500 focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md p-2 border"
                    placeholder="Enter Key Secret"
                    value={formData.razorpayKeySecret}
                    onChange={(e) => setFormData({ ...formData, razorpayKeySecret: e.target.value })}
                  />
                </div>
              </div>
            </div>

            <div className="pt-6 border-t border-gray-200 mt-6">
              <h3 className="text-lg leading-6 font-medium text-black">Commission Configuration</h3>
              <p className="mt-1 text-sm text-gray-500">Set percentage commission added to doctor fees for patients.</p>
              
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 mt-4">
                <div>
                  <label htmlFor="standard_commission" className="block text-sm font-medium text-black">
                    Standard Consultation Commission (%)
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <input
                      type="number"
                      name="standard_commission"
                      id="standard_commission"
                      className="text-black placeholder-gray-500 focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md p-2 border"
                      placeholder="e.g. 10"
                      value={formData.standardCommission}
                      onChange={(e) => setFormData({ ...formData, standardCommission: Number(e.target.value) })}
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="emergency_commission" className="block text-sm font-medium text-black">
                    Emergency Call Commission (%)
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <input
                      type="number"
                      name="emergency_commission"
                      id="emergency_commission"
                      className="text-black placeholder-gray-500 focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md p-2 border"
                      placeholder="e.g. 20"
                      value={formData.emergencyCommission}
                      onChange={(e) => setFormData({ ...formData, emergencyCommission: Number(e.target.value) })}
                    />
                  </div>
                </div>
              </div>
            </div>

            {message && (
              <div className={`p-4 rounded-md ${message.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
                {message.text}
              </div>
            )}

            <div className="flex justify-end">
              <button
                type="submit"
                disabled={mutation.isPending}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
              >
                <Save className="h-4 w-4 mr-2" />
                {mutation.isPending ? 'Saving...' : 'Save Settings'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
