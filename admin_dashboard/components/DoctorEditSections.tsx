'use client';

import { useState } from 'react';
import { Pencil, X, Check, Upload, Eye, Download } from 'lucide-react';

interface Props {
  doctor: any;
}

export default function DoctorEditSections({ doctor }: Props) {
  // ── Section edit states ──
  const [editingMain, setEditingMain] = useState(false);
  const [editingDocs, setEditingDocs] = useState(false);
  const [editingFinancial, setEditingFinancial] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  // ── Main Info state ──
  const [mainData, setMainData] = useState({
    name: doctor.name || '',
    specialization: doctor.specialization || '',
    email: doctor.email || '',
    phone: doctor.phone || '',
    licenseNumber: doctor.licenseNumber || '',
    experienceYears: doctor.experienceYears || '',
    about: doctor.about || '',
    qualifications: doctor.qualifications || '',
    hospitalAffiliation: doctor.hospitalAffiliation || '',
    profileImage: doctor.profileImage || '',
  });
  const [newProfileImage, setNewProfileImage] = useState<File | null>(null);
  const [profilePreview, setProfilePreview] = useState<string | null>(null);

  // ── Documents state ──
  const [documents, setDocuments] = useState<string[]>(doctor.documents || []);
  const [newDoc1, setNewDoc1] = useState<File | null>(null);
  const [newDoc2, setNewDoc2] = useState<File | null>(null);

  // ── Financial state ──
  const [financialData, setFinancialData] = useState({
    consultationFee: doctor.consultationFee || 500,
    emergencyFee: doctor.consultationFees?.emergency || '',
    bankName: doctor.bankDetails?.bankName || '',
    accountHolderName: doctor.bankDetails?.accountHolderName || '',
    accountNumber: doctor.bankDetails?.accountNumber || '',
    ifscCode: doctor.bankDetails?.ifscCode || '',
  });

  const showMsg = (msg: string, isError = false) => {
    if (isError) setError(msg); else setSuccess(msg);
    setTimeout(() => { setError(''); setSuccess(''); }, 3000);
  };

  const uploadFile = async (file: File): Promise<string | null> => {
    const fd = new FormData();
    fd.append('file', file);
    const res = await fetch('/api/upload', { method: 'POST', body: fd });
    if (!res.ok) return null;
    const data = await res.json();
    return data.urls?.[0] || null;
  };

  const saveToApi = async (body: any) => {
    const res = await fetch(`/api/doctors/${doctor._id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error('Failed to save');
    return res.json();
  };

  // ── Save Main Info ──
  const saveMain = async () => {
    setSaving(true);
    try {
      let profileImageUrl = mainData.profileImage;
      if (newProfileImage) {
        const url = await uploadFile(newProfileImage);
        if (url) profileImageUrl = url;
      }
      await saveToApi({
        name: mainData.name,
        specialization: mainData.specialization,
        email: mainData.email,
        phone: mainData.phone,
        licenseNumber: mainData.licenseNumber,
        experienceYears: mainData.experienceYears,
        about: mainData.about,
        qualifications: mainData.qualifications,
        hospitalAffiliation: mainData.hospitalAffiliation,
        profileImage: profileImageUrl,
      });
      setMainData(prev => ({ ...prev, profileImage: profileImageUrl }));
      setNewProfileImage(null);
      setProfilePreview(null);
      setEditingMain(false);
      showMsg('Main info saved successfully');
    } catch {
      showMsg('Failed to save main info', true);
    } finally {
      setSaving(false);
    }
  };

  // ── Save Documents ──
  const saveDocs = async () => {
    setSaving(true);
    try {
      const updatedDocs = [...documents];
      if (newDoc1) {
        const url = await uploadFile(newDoc1);
        if (url) updatedDocs[0] = url;
      }
      if (newDoc2) {
        const url = await uploadFile(newDoc2);
        if (url) updatedDocs[1] = url;
      }
      await saveToApi({ documents: updatedDocs });
      setDocuments(updatedDocs);
      setNewDoc1(null);
      setNewDoc2(null);
      setEditingDocs(false);
      showMsg('Documents saved successfully');
    } catch {
      showMsg('Failed to save documents', true);
    } finally {
      setSaving(false);
    }
  };

  // ── Save Financial ──
  const saveFinancial = async () => {
    setSaving(true);
    try {
      await saveToApi({
        consultationFee: Number(financialData.consultationFee),
        consultationFees: {
          standard: Number(financialData.consultationFee),
          emergency: Number(financialData.emergencyFee) || 0,
        },
        bankDetails: {
          bankName: financialData.bankName,
          accountHolderName: financialData.accountHolderName,
          accountNumber: financialData.accountNumber,
          ifscCode: financialData.ifscCode,
        },
      });
      setEditingFinancial(false);
      showMsg('Financial details saved successfully');
    } catch {
      showMsg('Failed to save financial details', true);
    } finally {
      setSaving(false);
    }
  };

  const resolveUrl = (url: string) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/uploads/')) return url;
    if (url.startsWith('/')) return `/uploads${url}`;
    return `/uploads/${url}`;
  };

  const inputCls = 'w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm text-gray-900 bg-white focus:outline-none focus:ring-1 focus:ring-blue-500';
  const labelCls = 'text-sm font-medium text-gray-500';

  return (
    <div className="space-y-6">
      {/* Toast */}
      {(success || error) && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-2 rounded shadow text-white text-sm ${error ? 'bg-red-500' : 'bg-green-500'}`}>
          {success || error}
        </div>
      )}

      {/* ── SECTION 1: Main Info ── */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-semibold text-gray-800">Main Information</h3>
          {!editingMain ? (
            <button onClick={() => setEditingMain(true)} className="inline-flex items-center px-3 py-1.5 text-sm text-blue-600 border border-blue-200 rounded hover:bg-blue-50">
              <Pencil className="w-3.5 h-3.5 mr-1" /> Edit
            </button>
          ) : (
            <div className="flex space-x-2">
              <button onClick={() => { setEditingMain(false); setNewProfileImage(null); setProfilePreview(null); }} className="inline-flex items-center px-3 py-1.5 text-sm text-gray-600 border border-gray-200 rounded hover:bg-gray-50">
                <X className="w-3.5 h-3.5 mr-1" /> Cancel
              </button>
              <button onClick={saveMain} disabled={saving} className="inline-flex items-center px-3 py-1.5 text-sm text-white bg-blue-600 rounded hover:bg-blue-700 disabled:opacity-50">
                <Check className="w-3.5 h-3.5 mr-1" /> {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          )}
        </div>

        {/* Profile Picture */}
        <div className="flex items-center space-x-4 mb-4">
          <div className="w-16 h-16 rounded-full overflow-hidden bg-blue-100 flex items-center justify-center border-2 border-blue-100 flex-shrink-0">
            {profilePreview ? (
              <img src={profilePreview} className="w-full h-full object-cover" alt="preview" />
            ) : mainData.profileImage ? (
              <img src={resolveUrl(mainData.profileImage)} className="w-full h-full object-cover" alt="profile" />
            ) : (
              <span className="text-2xl text-blue-400">👤</span>
            )}
          </div>
          {editingMain && (
            <label className="cursor-pointer inline-flex items-center px-3 py-1.5 text-sm font-medium text-blue-700 bg-blue-50 border border-blue-400 rounded hover:bg-blue-100">
              <Upload className="w-3.5 h-3.5 mr-1" /> Change Photo
              <input type="file" className="sr-only" accept="image/jpeg,image/png"
                onChange={(e) => {
                  const f = e.target.files?.[0] || null;
                  setNewProfileImage(f);
                  if (f) setProfilePreview(URL.createObjectURL(f));
                }}
              />
            </label>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[
            { label: 'Name', key: 'name' },
            { label: 'Specialization', key: 'specialization' },
            { label: 'Email', key: 'email' },
            { label: 'Phone', key: 'phone' },
            { label: 'License Number', key: 'licenseNumber' },
            { label: 'Experience (Years)', key: 'experienceYears' },
            { label: 'Qualifications', key: 'qualifications' },
            { label: 'Hospital Affiliation', key: 'hospitalAffiliation' },
          ].map(({ label, key }) => (
            <div key={key}>
              <label className={labelCls}>{label}</label>
              {editingMain ? (
                <input className={inputCls} value={(mainData as any)[key]} onChange={(e) => setMainData(prev => ({ ...prev, [key]: e.target.value }))} />
              ) : (
                <p className="mt-1 text-sm text-gray-900">{(mainData as any)[key] || 'Not specified'}</p>
              )}
            </div>
          ))}
          <div className="md:col-span-2">
            <label className={labelCls}>About</label>
            {editingMain ? (
              <textarea className={inputCls} rows={3} value={mainData.about} onChange={(e) => setMainData(prev => ({ ...prev, about: e.target.value }))} />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{mainData.about || 'No description provided.'}</p>
            )}
          </div>
        </div>
      </div>

      {/* ── SECTION 3: Documents ── */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-semibold text-gray-800">Documents</h3>
          {!editingDocs ? (
            <button onClick={() => setEditingDocs(true)} className="inline-flex items-center px-3 py-1.5 text-sm text-blue-600 border border-blue-200 rounded hover:bg-blue-50">
              <Pencil className="w-3.5 h-3.5 mr-1" /> Edit
            </button>
          ) : (
            <div className="flex space-x-2">
              <button onClick={() => { setEditingDocs(false); setNewDoc1(null); setNewDoc2(null); }} className="inline-flex items-center px-3 py-1.5 text-sm text-gray-600 border border-gray-200 rounded hover:bg-gray-50">
                <X className="w-3.5 h-3.5 mr-1" /> Cancel
              </button>
              <button onClick={saveDocs} disabled={saving} className="inline-flex items-center px-3 py-1.5 text-sm text-white bg-blue-600 rounded hover:bg-blue-700 disabled:opacity-50">
                <Check className="w-3.5 h-3.5 mr-1" /> {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {[0, 1].map((i) => {
            const docUrl = documents[i] ? resolveUrl(documents[i]) : null;
            const newFile = i === 0 ? newDoc1 : newDoc2;
            return (
              <div key={i} className="space-y-2">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium text-gray-700">Document {i + 1}</p>
                  {docUrl && !editingDocs && (
                    <div className="flex space-x-2">
                      <button
                        onClick={() => setPreviewUrl(docUrl)}
                        className="inline-flex items-center px-2 py-1 text-xs font-medium text-blue-700 bg-blue-50 border border-blue-400 rounded hover:bg-blue-100"
                      >
                        <Eye className="w-3 h-3 mr-1" /> View
                      </button>
                      <a
                        href={docUrl}
                        download
                        className="inline-flex items-center px-2 py-1 text-xs font-medium text-green-700 bg-green-50 border border-green-400 rounded hover:bg-green-100"
                      >
                        <Download className="w-3 h-3 mr-1" /> Download
                      </a>
                    </div>
                  )}
                </div>
                {docUrl && !newFile && (
                  <div
                    className="border rounded-lg overflow-hidden bg-gray-50 p-2 cursor-pointer hover:opacity-90"
                    onClick={() => !editingDocs && setPreviewUrl(docUrl)}
                  >
                    <img src={docUrl} alt={`Document ${i + 1}`} className="w-full h-auto object-contain max-h-[150px]" />
                  </div>
                )}
                {newFile && (
                  <div className="border rounded-lg overflow-hidden bg-gray-50 p-2">
                    <img src={URL.createObjectURL(newFile)} alt="new doc" className="w-full h-auto object-contain max-h-[150px]" />
                  </div>
                )}
                {editingDocs && (
                  <label className="cursor-pointer inline-flex items-center px-3 py-1.5 text-sm font-medium text-blue-700 bg-blue-50 border border-blue-400 rounded hover:bg-blue-100">
                    <Upload className="w-3.5 h-3.5 mr-1" /> {docUrl ? 'Replace' : 'Upload'}
                    <input type="file" className="sr-only" accept=".pdf,.jpg,.jpeg,.png"
                      onChange={(e) => {
                        const f = e.target.files?.[0] || null;
                        if (i === 0) setNewDoc1(f); else setNewDoc2(f);
                      }}
                    />
                  </label>
                )}
                {!docUrl && !newFile && <p className="text-xs text-gray-400 italic">No document uploaded</p>}
              </div>
            );
          })}
        </div>
      </div>

      {/* Document Preview Popup */}
      {previewUrl && (
        <div className="fixed inset-0 bg-black bg-opacity-80 z-50 flex items-center justify-center p-4">
          <div className="relative bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col">
            <div className="flex items-center justify-between px-4 py-3 border-b">
              <span className="font-semibold text-gray-800">Document Preview</span>
              <div className="flex items-center space-x-2">
                <a
                  href={previewUrl}
                  download
                  className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded"
                >
                  <Download className="w-4 h-4 mr-1" /> Download
                </a>
                <button
                  onClick={() => setPreviewUrl(null)}
                  className="p-1.5 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>
            <div className="overflow-auto flex-1 p-4 flex items-center justify-center bg-gray-50">
              {previewUrl.toLowerCase().includes('.pdf') ? (
                <iframe src={previewUrl} className="w-full h-[75vh]" title="Document Preview" />
              ) : (
                <img src={previewUrl} alt="Document Preview" className="max-w-full max-h-[75vh] object-contain" />
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── SECTION 4: Financial Details ── */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-semibold text-gray-800">Financial Details</h3>
          {!editingFinancial ? (
            <button onClick={() => setEditingFinancial(true)} className="inline-flex items-center px-3 py-1.5 text-sm text-blue-600 border border-blue-200 rounded hover:bg-blue-50">
              <Pencil className="w-3.5 h-3.5 mr-1" /> Edit
            </button>
          ) : (
            <div className="flex space-x-2">
              <button onClick={() => setEditingFinancial(false)} className="inline-flex items-center px-3 py-1.5 text-sm text-gray-600 border border-gray-200 rounded hover:bg-gray-50">
                <X className="w-3.5 h-3.5 mr-1" /> Cancel
              </button>
              <button onClick={saveFinancial} disabled={saving} className="inline-flex items-center px-3 py-1.5 text-sm text-white bg-blue-600 rounded hover:bg-blue-700 disabled:opacity-50">
                <Check className="w-3.5 h-3.5 mr-1" /> {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[
            { label: 'Consultation Fee (₹)', key: 'consultationFee', type: 'number' },
            { label: 'Emergency Fee (₹)', key: 'emergencyFee', type: 'number' },
            { label: 'Bank Name', key: 'bankName' },
            { label: 'Account Holder Name', key: 'accountHolderName' },
            { label: 'Account Number', key: 'accountNumber' },
            { label: 'IFSC Code', key: 'ifscCode' },
          ].map(({ label, key, type }) => (
            <div key={key}>
              <label className={labelCls}>{label}</label>
              {editingFinancial ? (
                <input type={type || 'text'} className={inputCls} value={(financialData as any)[key]} onChange={(e) => setFinancialData(prev => ({ ...prev, [key]: e.target.value }))} />
              ) : (
                <p className="mt-1 text-sm text-gray-900">{(financialData as any)[key] || '-'}</p>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
