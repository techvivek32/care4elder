'use client';

import { useState } from 'react';
import { CreditCard, Pencil, X, Check } from 'lucide-react';

export default function FinancialEditSection({ doctor }: { doctor: any }) {
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const [data, setData] = useState({
    consultationFee: doctor.consultationFee || 500,
    emergencyFee: doctor.consultationFees?.emergency || '',
    walletBalance: doctor.walletBalance || 0,
    bankName: doctor.bankDetails?.bankName || '',
    accountHolderName: doctor.bankDetails?.accountHolderName || '',
    accountNumber: doctor.bankDetails?.accountNumber || '',
    ifscCode: doctor.bankDetails?.ifscCode || '',
  });

  const showMsg = (msg: string, isError = false) => {
    if (isError) setError(msg); else setSuccess(msg);
    setTimeout(() => { setError(''); setSuccess(''); }, 3000);
  };

  const save = async () => {
    setSaving(true);
    try {
      const res = await fetch(`/api/doctors/${doctor._id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          consultationFee: Number(data.consultationFee),
          consultationFees: {
            standard: Number(data.consultationFee),
            emergency: Number(data.emergencyFee) || 0,
          },
          bankDetails: {
            bankName: data.bankName,
            accountHolderName: data.accountHolderName,
            accountNumber: data.accountNumber,
            ifscCode: data.ifscCode,
          },
        }),
      });
      if (!res.ok) throw new Error('Failed');
      setEditing(false);
      showMsg('Financial details saved');
    } catch {
      showMsg('Failed to save', true);
    } finally {
      setSaving(false);
    }
  };

  const inputCls = 'w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm text-gray-900 bg-white focus:outline-none focus:ring-1 focus:ring-blue-500';

  return (
    <div className="bg-white shadow rounded-lg p-6">
      {/* Toast */}
      {(success || error) && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-2 rounded shadow text-white text-sm ${error ? 'bg-red-500' : 'bg-green-500'}`}>
          {success || error}
        </div>
      )}

      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-medium text-gray-900 flex items-center">
          <CreditCard className="w-5 h-5 mr-2 text-green-500" />
          Financial Details
        </h3>
        {!editing ? (
          <button onClick={() => setEditing(true)} className="inline-flex items-center px-3 py-1.5 text-sm text-blue-600 border border-blue-200 rounded hover:bg-blue-50">
            <Pencil className="w-3.5 h-3.5 mr-1" /> Edit
          </button>
        ) : (
          <div className="flex space-x-2">
            <button onClick={() => setEditing(false)} className="inline-flex items-center px-3 py-1.5 text-sm text-gray-600 border border-gray-300 rounded hover:bg-gray-50">
              <X className="w-3.5 h-3.5 mr-1" /> Cancel
            </button>
            <button onClick={save} disabled={saving} className="inline-flex items-center px-3 py-1.5 text-sm text-white bg-blue-600 rounded hover:bg-blue-700 disabled:opacity-50">
              <Check className="w-3.5 h-3.5 mr-1" /> {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        )}
      </div>

      <div className="space-y-3">
        {/* Consultation Fee */}
        <div className="flex justify-between items-center py-2 border-b">
          <span className="text-gray-500 text-sm">Consultation Fee</span>
          {editing ? (
            <input type="number" className={`${inputCls} w-28 text-right`} value={data.consultationFee}
              onChange={(e) => setData(p => ({ ...p, consultationFee: e.target.value }))} />
          ) : (
            <span className="font-semibold text-gray-900">₹{data.consultationFee}</span>
          )}
        </div>

        {/* Emergency Fee */}
        <div className="flex justify-between items-center py-2 border-b">
          <span className="text-gray-500 text-sm">Emergency Fee</span>
          {editing ? (
            <input type="number" className={`${inputCls} w-28 text-right`} value={data.emergencyFee}
              onChange={(e) => setData(p => ({ ...p, emergencyFee: e.target.value }))} />
          ) : (
            <span className="font-semibold text-gray-900">{data.emergencyFee ? `₹${data.emergencyFee}` : '-'}</span>
          )}
        </div>

        {/* Wallet Balance - read only */}
        <div className="flex justify-between items-center py-2 border-b">
          <span className="text-gray-500 text-sm">Wallet Balance</span>
          <span className="font-semibold text-green-600">₹{Number(data.walletBalance).toFixed(2)}</span>
        </div>

        {/* Bank Details */}
        <div className="mt-3 pt-3 border-t bg-gray-50 p-3 rounded-lg">
          <h4 className="text-sm font-bold text-black mb-3 border-b pb-1">Bank Information</h4>
          <div className="space-y-2 text-sm">
            {[
              { label: 'Bank Name', key: 'bankName' },
              { label: 'Holder Name', key: 'accountHolderName' },
              { label: 'Account No', key: 'accountNumber' },
              { label: 'IFSC Code', key: 'ifscCode' },
            ].map(({ label, key }) => (
              <div key={key} className="flex justify-between items-center border-b border-gray-200 pb-1">
                <span className="text-gray-700 font-semibold">{label}</span>
                {editing ? (
                  <input className={`${inputCls} w-36 text-right font-mono`} value={(data as any)[key]}
                    onChange={(e) => setData(p => ({ ...p, [key]: e.target.value }))} />
                ) : (
                  <span className="text-black font-bold font-mono">{(data as any)[key] || '-'}</span>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
