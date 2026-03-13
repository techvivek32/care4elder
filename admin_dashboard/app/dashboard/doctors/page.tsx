'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserPlus, Phone, CheckCircle, XCircle, Trash2, Plus, Eye, EyeOff, Upload, X } from 'lucide-react';
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

async function addDoctor(doctorData: any) {
  const formData = new FormData();
  
  // Add all text fields
  Object.keys(doctorData).forEach(key => {
    if (key !== 'medicalCertificate' && key !== 'idProof') {
      formData.append(key, doctorData[key]);
    }
  });
  
  // Add files
  if (doctorData.medicalCertificate) {
    formData.append('medicalCertificate', doctorData.medicalCertificate);
  }
  if (doctorData.idProof) {
    formData.append('idProof', doctorData.idProof);
  }
  
  const res = await fetch('/api/doctors', {
    method: 'POST',
    body: formData,
  });
  
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to add doctor');
  }
  return res.json();
}

export default function DoctorsPage() {
  const queryClient = useQueryClient();
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [selectAll, setSelectAll] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  
  // Form state
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    idNumber: '',
    password: '',
    confirmPassword: '',
    licenseNumber: '',
    specialization: '',
    qualifications: '',
    experience: '',
    hospitalAddress: '',
    medicalCertificate: null as File | null,
    idProof: null as File | null,
  });
  
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  
  const specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Orthopedist',
    'Pediatrician',
    'Neurologist',
    'Psychiatrist',
    'Gynecologist',
  ];
  
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

  const addMutation = useMutation({
    mutationFn: addDoctor,
    onSuccess: () => {
      setShowAddForm(false);
      resetForm();
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

  const resetForm = () => {
    setFormData({
      fullName: '',
      email: '',
      phone: '',
      idNumber: '',
      password: '',
      confirmPassword: '',
      licenseNumber: '',
      specialization: '',
      qualifications: '',
      experience: '',
      hospitalAddress: '',
      medicalCertificate: null,
      idProof: null,
    });
    setFormErrors({});
    setShowPassword(false);
    setShowConfirmPassword(false);
  };

  const validateForm = () => {
    const errors: Record<string, string> = {};
    
    if (!formData.fullName.trim()) errors.fullName = 'Full name is required';
    if (!formData.email.trim()) errors.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(formData.email)) errors.email = 'Email is invalid';
    if (!formData.phone.trim()) errors.phone = 'Phone number is required';
    if (!formData.idNumber.trim()) errors.idNumber = 'ID number is required';
    if (!formData.password) errors.password = 'Password is required';
    else if (formData.password.length < 6) errors.password = 'Password must be at least 6 characters';
    if (formData.password !== formData.confirmPassword) errors.confirmPassword = 'Passwords do not match';
    if (!formData.licenseNumber.trim()) errors.licenseNumber = 'Medical license number is required';
    if (!formData.specialization) errors.specialization = 'Specialization is required';
    if (!formData.qualifications.trim()) errors.qualifications = 'Qualifications are required';
    if (!formData.experience.trim()) errors.experience = 'Years of experience is required';
    else if (isNaN(Number(formData.experience))) errors.experience = 'Experience must be a number';
    if (!formData.hospitalAddress.trim()) errors.hospitalAddress = 'Hospital/Clinic address is required';
    if (!formData.medicalCertificate) errors.medicalCertificate = 'Medical certificate is required';
    if (!formData.idProof) errors.idProof = 'ID proof is required';
    
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm()) {
      addMutation.mutate(formData);
    }
  };

  const handleFileChange = (field: 'medicalCertificate' | 'idProof', file: File | null) => {
    if (file) {
      // Validate file size (5MB max)
      if (file.size > 5 * 1024 * 1024) {
        setFormErrors(prev => ({ ...prev, [field]: 'File size must be less than 5MB' }));
        return;
      }
      
      // Validate file type
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
      if (!allowedTypes.includes(file.type)) {
        setFormErrors(prev => ({ ...prev, [field]: 'Only PDF, JPG, and PNG files are allowed' }));
        return;
      }
    }
    
    setFormData(prev => ({ ...prev, [field]: file }));
    setFormErrors(prev => ({ ...prev, [field]: '' }));
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading doctors</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Doctor Management</h1>
        <button
          onClick={() => setShowAddForm(true)}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          <Plus className="h-4 w-4 mr-2" /> Add Doctor
        </button>
      </div>

      {/* Add Doctor Modal */}
      {showAddForm && (
        <div className="fixed inset-0 bg-gray-900 bg-opacity-75 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 rounded-t-lg">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-bold text-gray-900">Add New Doctor</h3>
                <button
                  onClick={() => {
                    setShowAddForm(false);
                    resetForm();
                  }}
                  className="text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>
            </div>
            
            <div className="px-6 py-6">
              <form onSubmit={handleSubmit} className="space-y-6">
              {/* Personal Information */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Personal Information</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Full Name *</label>
                    <input
                      type="text"
                      value={formData.fullName}
                      onChange={(e) => setFormData(prev => ({ ...prev, fullName: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="Dr. John Doe"
                    />
                    {formErrors.fullName && <p className="text-red-500 text-xs mt-1">{formErrors.fullName}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Email Address *</label>
                    <input
                      type="email"
                      value={formData.email}
                      onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="doctor@example.com"
                    />
                    {formErrors.email && <p className="text-red-500 text-xs mt-1">{formErrors.email}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Phone Number *</label>
                    <input
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => setFormData(prev => ({ ...prev, phone: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="+919876543210"
                    />
                    {formErrors.phone && <p className="text-red-500 text-xs mt-1">{formErrors.phone}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">ID Number *</label>
                    <input
                      type="text"
                      value={formData.idNumber}
                      onChange={(e) => setFormData(prev => ({ ...prev, idNumber: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="1234567890"
                    />
                    {formErrors.idNumber && <p className="text-red-500 text-xs mt-1">{formErrors.idNumber}</p>}
                  </div>
                </div>
              </div>

              {/* Account Security */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Account Security</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Password *</label>
                    <div className="relative">
                      <input
                        type={showPassword ? "text" : "password"}
                        value={formData.password}
                        onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
                        className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 pr-10 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                        placeholder="Enter password"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute inset-y-0 right-0 pr-3 flex items-center"
                      >
                        {showPassword ? <EyeOff className="h-4 w-4 text-gray-400" /> : <Eye className="h-4 w-4 text-gray-400" />}
                      </button>
                    </div>
                    {formErrors.password && <p className="text-red-500 text-xs mt-1">{formErrors.password}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Confirm Password *</label>
                    <div className="relative">
                      <input
                        type={showConfirmPassword ? "text" : "password"}
                        value={formData.confirmPassword}
                        onChange={(e) => setFormData(prev => ({ ...prev, confirmPassword: e.target.value }))}
                        className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 pr-10 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                        placeholder="Confirm password"
                      />
                      <button
                        type="button"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        className="absolute inset-y-0 right-0 pr-3 flex items-center"
                      >
                        {showConfirmPassword ? <EyeOff className="h-4 w-4 text-gray-400" /> : <Eye className="h-4 w-4 text-gray-400" />}
                      </button>
                    </div>
                    {formErrors.confirmPassword && <p className="text-red-500 text-xs mt-1">{formErrors.confirmPassword}</p>}
                  </div>
                </div>
              </div>

              {/* Professional Credentials */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Professional Credentials</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Medical License Number *</label>
                    <input
                      type="text"
                      value={formData.licenseNumber}
                      onChange={(e) => setFormData(prev => ({ ...prev, licenseNumber: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="MCI-12345"
                    />
                    {formErrors.licenseNumber && <p className="text-red-500 text-xs mt-1">{formErrors.licenseNumber}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Specialization *</label>
                    <select
                      value={formData.specialization}
                      onChange={(e) => setFormData(prev => ({ ...prev, specialization: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                    >
                      <option value="">Select Specialization</option>
                      {specializations.map(spec => (
                        <option key={spec} value={spec}>{spec}</option>
                      ))}
                    </select>
                    {formErrors.specialization && <p className="text-red-500 text-xs mt-1">{formErrors.specialization}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Qualifications *</label>
                    <input
                      type="text"
                      value={formData.qualifications}
                      onChange={(e) => setFormData(prev => ({ ...prev, qualifications: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="MBBS, MD, etc."
                    />
                    {formErrors.qualifications && <p className="text-red-500 text-xs mt-1">{formErrors.qualifications}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Years of Experience *</label>
                    <input
                      type="number"
                      value={formData.experience}
                      onChange={(e) => setFormData(prev => ({ ...prev, experience: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="5"
                      min="0"
                    />
                    {formErrors.experience && <p className="text-red-500 text-xs mt-1">{formErrors.experience}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Hospital/Clinic Address *</label>
                    <input
                      type="text"
                      value={formData.hospitalAddress}
                      onChange={(e) => setFormData(prev => ({ ...prev, hospitalAddress: e.target.value }))}
                      className="mt-1 block w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:bg-white"
                      placeholder="City General Hospital"
                    />
                    {formErrors.hospitalAddress && <p className="text-red-500 text-xs mt-1">{formErrors.hospitalAddress}</p>}
                  </div>
                </div>
              </div>

              {/* Documents */}
              <div>
                <h4 className="text-md font-semibold text-gray-800 mb-3">Documents</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Medical Certificate *</label>
                    <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                      <div className="space-y-1 text-center">
                        {formData.medicalCertificate ? (
                          <div className="flex items-center space-x-2">
                            <span className="text-sm text-gray-600">{formData.medicalCertificate.name}</span>
                            <button
                              type="button"
                              onClick={() => handleFileChange('medicalCertificate', null)}
                              className="text-red-500 hover:text-red-700"
                            >
                              <X className="h-4 w-4" />
                            </button>
                          </div>
                        ) : (
                          <>
                            <Upload className="mx-auto h-12 w-12 text-gray-400" />
                            <div className="flex text-sm text-gray-600">
                              <label className="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500">
                                <span>Upload a file</span>
                                <input
                                  type="file"
                                  className="sr-only"
                                  accept=".pdf,.jpg,.jpeg,.png"
                                  onChange={(e) => handleFileChange('medicalCertificate', e.target.files?.[0] || null)}
                                />
                              </label>
                            </div>
                            <p className="text-xs text-gray-500">PDF, JPG, PNG up to 5MB</p>
                          </>
                        )}
                      </div>
                    </div>
                    {formErrors.medicalCertificate && <p className="text-red-500 text-xs mt-1">{formErrors.medicalCertificate}</p>}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">ID Proof *</label>
                    <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                      <div className="space-y-1 text-center">
                        {formData.idProof ? (
                          <div className="flex items-center space-x-2">
                            <span className="text-sm text-gray-600">{formData.idProof.name}</span>
                            <button
                              type="button"
                              onClick={() => handleFileChange('idProof', null)}
                              className="text-red-500 hover:text-red-700"
                            >
                              <X className="h-4 w-4" />
                            </button>
                          </div>
                        ) : (
                          <>
                            <Upload className="mx-auto h-12 w-12 text-gray-400" />
                            <div className="flex text-sm text-gray-600">
                              <label className="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500">
                                <span>Upload a file</span>
                                <input
                                  type="file"
                                  className="sr-only"
                                  accept=".pdf,.jpg,.jpeg,.png"
                                  onChange={(e) => handleFileChange('idProof', e.target.files?.[0] || null)}
                                />
                              </label>
                            </div>
                            <p className="text-xs text-gray-500">PDF, JPG, PNG up to 5MB</p>
                          </>
                        )}
                      </div>
                    </div>
                    {formErrors.idProof && <p className="text-red-500 text-xs mt-1">{formErrors.idProof}</p>}
                  </div>
                </div>
              </div>

              {/* Submit Buttons */}
              <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => {
                    setShowAddForm(false);
                    resetForm();
                  }}
                  className="px-6 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={addMutation.isPending}
                  className="px-6 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {addMutation.isPending ? 'Adding...' : 'Add Doctor'}
                </button>
              </div>
            </form>
            </div>
          </div>
        </div>
      )}

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
